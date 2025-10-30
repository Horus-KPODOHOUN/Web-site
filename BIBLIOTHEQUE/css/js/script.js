// Données des livres
const defaultBooks = [
    {
        id: 1,
        title: "L'Étranger",
        author: "Albert Camus",
        description: "Un roman philosophique qui explore l'absurdité de la vie à travers le personnage de Meursault.",
        cover: "https://via.placeholder.com/200x300/3498db/ffffff?text=L'Étranger",
        category: "Littérature",
        hasAudio: true,
        hasPDF: true
    },
    {
        id: 2,
        title: "1984",
        author: "George Orwell",
        description: "Une dystopie célèbre sur un régime totalitaire qui surveille chaque aspect de la vie des citoyens.",
        cover: "https://via.placeholder.com/200x300/e74c3c/ffffff?text=1984",
        category: "Science-fiction",
        hasAudio: true,
        hasPDF: true
    },
    {
        id: 3,
        title: "Le Petit Prince",
        author: "Antoine de Saint-Exupéry",
        description: "Un conte poétique et philosophique sous l'apparence d'un livre pour enfants.",
        cover: "https://via.placeholder.com/200x300/2ecc71/ffffff?text=Le+Petit+Prince",
        category: "Jeunesse",
        hasAudio: true,
        hasPDF: true
    },
    {
        id: 4,
        title: "Les Misérables",
        author: "Victor Hugo",
        description: "Une fresque sociale et historique qui suit la vie de Jean Valjean dans la France du XIXe siècle.",
        cover: "https://via.placeholder.com/200x300/9b59b6/ffffff?text=Les+Misérables",
        category: "Classique",
        hasAudio: false,
        hasPDF: true
    },
    {
        id: 5,
        title: "Harry Potter à l'École des Sorciers",
        author: "J.K. Rowling",
        description: "Le premier tome de la saga fantastique qui a captivé des millions de lecteurs à travers le monde.",
        cover: "https://via.placeholder.com/200x300/f39c12/ffffff?text=Harry+Potter",
        category: "Fantasy",
        hasAudio: true,
        hasPDF: true
    },
    {
        id: 6,
        title: "Le Seigneur des Anneaux",
        author: "J.R.R. Tolkien",
        description: "Une épopée fantastique qui suit la quête de Frodon Sacquet pour détruire l'Anneau Unique.",
        cover: "https://via.placeholder.com/200x300/34495e/ffffff?text=Le+Seigneur+des+Anneaux",
        category: "Fantasy",
        hasAudio: true,
        hasPDF: true
    }
];

// Variables pour le carousel
let currentSlide = 0;
let slideInterval;

// Fonction pour récupérer les livres depuis l'admin
function getBooksFromAdmin() {
    try {
        const adminBooks = JSON.parse(localStorage.getItem('admin_livres')) || [];
        
        // Transformer les livres de l'admin au format de la bibliothèque
        return adminBooks.map(book => ({
            id: book.id,
            title: book.titre,
            author: book.auteur,
            description: book.description,
            cover: book.couverture,
            category: book.categorie,
            hasAudio: book.hasAudio,
            hasPDF: book.hasPDF,
            statut: book.statut,
            dateCreation: book.dateCreation,
            isFromAdmin: true
        }));
    } catch (error) {
        console.error('Erreur lors de la récupération des livres admin:', error);
        return [];
    }
}

// Fonction pour charger tous les livres (uniquement pour la bibliothèque)
function loadBooks() {
    const adminBooks = getBooksFromAdmin();
    let allBooks = [...adminBooks];
    
    // Ajouter les livres par défaut seulement si aucun livre admin n'existe
    if (adminBooks.length === 0) {
        allBooks = [...defaultBooks];
    }
    
    // Filtrer seulement les livres actifs
    const activeBooks = allBooks.filter(book => 
        book.statut === 'actif' || book.statut === undefined
    );
    
    return activeBooks;
}

// Fonction pour afficher les livres en vue grille (uniquement pour la bibliothèque)
function displayBooks(booksToDisplay, containerId) {
    const booksContainer = document.getElementById(containerId);
    if (!booksContainer) return;
    
    booksContainer.innerHTML = '';
    
    if (booksToDisplay.length === 0) {
        booksContainer.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 3rem; color: #666;">
                <i class="fas fa-book" style="font-size: 3rem; margin-bottom: 1rem; display: block;"></i>
                <h3>Aucun livre disponible</h3>
                <p>Les livres ajoutés par l'administrateur apparaîtront ici.</p>
            </div>
        `;
        return;
    }
    
    booksToDisplay.forEach(book => {
        const bookCard = document.createElement('div');
        bookCard.className = 'book-card';
        
        bookCard.innerHTML = `
            <div class="book-cover">
                <img src="${book.cover}" alt="${book.title}" onerror="this.src='https://via.placeholder.com/200x300/ecf0f1/34495e?text=📚'">
                <span class="pdf-badge">PDF</span>
            </div>
            <div class="book-info">
                <div class="book-title">${book.title}</div>
                <div class="book-author">${book.author}</div>
                <div class="book-description">${book.description}</div>
                <div class="reading-options">
                    <button class="reading-option pdf" data-id="${book.id}">
                        <i class="fas fa-book-open"></i> Lire PDF
                    </button>
                    ${book.hasAudio ? 
                        `<button class="reading-option audio" data-id="${book.id}">
                            <i class="fas fa-headphones"></i> Écouter
                        </button>` : 
                        '<button class="reading-option audio" disabled>\
                            <i class="fas fa-headphones"></i> Audio indisponible\
                         </button>'
                    }
                </div>
            </div>
        `;
        
        booksContainer.appendChild(bookCard);
    });
    
    addReadingEventListeners();
}

// Fonction pour afficher les livres en vue liste (uniquement pour la bibliothèque)
function displayBooksList(booksToDisplay, containerId) {
    const booksContainer = document.getElementById(containerId);
    if (!booksContainer) return;
    
    booksContainer.innerHTML = '';
    
    if (booksToDisplay.length === 0) {
        booksContainer.innerHTML = `
            <div style="text-align: center; padding: 3rem; color: #666;">
                <i class="fas fa-book" style="font-size: 3rem; margin-bottom: 1rem; display: block;"></i>
                <h3>Aucun livre disponible</h3>
                <p>Les livres ajoutés par l'administrateur apparaîtront ici.</p>
            </div>
        `;
        return;
    }
    
    booksToDisplay.forEach(book => {
        const bookItem = document.createElement('div');
        bookItem.className = 'book-item-list';
        
        bookItem.innerHTML = `
            <div class="book-cover">
                <img src="${book.cover}" alt="${book.title}" onerror="this.src='https://via.placeholder.com/200x300/ecf0f1/34495e?text=📚'">
                <span class="pdf-badge">PDF</span>
            </div>
            <div class="book-info">
                <div class="book-main-info">
                    <div class="book-title">${book.title}</div>
                    <div class="book-author">${book.author}</div>
                    <div class="book-description">${book.description}</div>
                    <div class="book-meta">
                        <span class="book-meta-item">
                            <i class="fas fa-book"></i>
                            ${book.category}
                        </span>
                        <span class="book-meta-item">
                            <i class="fas fa-headphones"></i>
                            ${book.hasAudio ? 'Audio disponible' : 'Audio indisponible'}
                        </span>
                    </div>
                </div>
                <div class="reading-options">
                    <button class="reading-option pdf" data-id="${book.id}">
                        <i class="fas fa-book-open"></i> Lire PDF
                    </button>
                    ${book.hasAudio ? 
                        `<button class="reading-option audio" data-id="${book.id}">
                            <i class="fas fa-headphones"></i> Écouter
                        </button>` : 
                        '<button class="reading-option audio" disabled>\
                            <i class="fas fa-headphones"></i> Audio indisponible\
                         </button>'
                    }
                </div>
            </div>
        `;
        
        booksContainer.appendChild(bookItem);
    });
    
    addReadingEventListeners();
}

// Fonction pour gérer les événements de lecture (uniquement pour la bibliothèque)
function addReadingEventListeners() {
    // Boutons PDF
    document.querySelectorAll('.reading-option.pdf').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            if (this.disabled) return;
            
            const bookId = this.getAttribute('data-id');
            const books = loadBooks();
            const book = books.find(b => b.id == bookId);
            
            if (book) {
                openPDFReader(book);
            }
        });
    });
    
    // Boutons Audio
    document.querySelectorAll('.reading-option.audio').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            if (this.disabled) return;
            
            const bookId = this.getAttribute('data-id');
            const books = loadBooks();
            const book = books.find(b => b.id == bookId);
            
            if (book) {
                openAudioPlayer(book);
            }
        });
    });
}

// Fonction pour ouvrir le lecteur PDF
function openPDFReader(book) {
    alert(`Ouverture du PDF : ${book.title}\n\nCette fonctionnalité ouvrirait le lecteur PDF intégré pour le livre "${book.title}" de ${book.author}.`);
}

// Fonction pour ouvrir le lecteur audio
function openAudioPlayer(book) {
    const audioPlayer = document.getElementById('audio-player');
    const playerTitle = audioPlayer.querySelector('.player-title');
    const playerAuthor = audioPlayer.querySelector('.player-author');
    const playerCover = audioPlayer.querySelector('img');
    
    playerTitle.textContent = book.title;
    playerAuthor.textContent = book.author;
    playerCover.src = book.cover;
    
    audioPlayer.style.display = 'block';
}

// Fermer le lecteur audio
document.getElementById('close-player')?.addEventListener('click', function() {
    document.getElementById('audio-player').style.display = 'none';
});

// Gestion du carousel
function initCarousel() {
    const slides = document.querySelector('.carousel-slides');
    const dots = document.querySelectorAll('.carousel-dot');
    const prevBtn = document.querySelector('.carousel-prev');
    const nextBtn = document.querySelector('.carousel-next');
    
    if (!slides || !dots.length) return;
    
    function goToSlide(slideIndex) {
        currentSlide = slideIndex;
        slides.style.transform = `translateX(-${currentSlide * 33.333}%)`;
        
        // Mettre à jour les dots
        dots.forEach((dot, index) => {
            dot.classList.toggle('active', index === currentSlide);
        });
    }
    
    function nextSlide() {
        currentSlide = (currentSlide + 1) % 3;
        goToSlide(currentSlide);
    }
    
    function prevSlide() {
        currentSlide = (currentSlide - 1 + 3) % 3;
        goToSlide(currentSlide);
    }
    
    // Événements pour les boutons
    if (nextBtn) nextBtn.addEventListener('click', nextSlide);
    if (prevBtn) prevBtn.addEventListener('click', prevSlide);
    
    // Événements pour les dots
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => goToSlide(index));
    });
    
    // Défilement automatique
    startCarousel();
    
    // Arrêter le défilement automatique quand la souris est sur le carousel
    const carousel = document.querySelector('.carousel');
    if (carousel) {
        carousel.addEventListener('mouseenter', () => {
            clearInterval(slideInterval);
        });
        
        carousel.addEventListener('mouseleave', () => {
            startCarousel();
        });
    }
}

function startCarousel() {
    clearInterval(slideInterval);
    slideInterval = setInterval(() => {
        const nextBtn = document.querySelector('.carousel-next');
        if (nextBtn) nextBtn.click();
    }, 5000);
}

// Gestion du changement de vue (uniquement pour la bibliothèque)
function setupViewToggle() {
    const viewButtons = document.querySelectorAll('.view-btn');
    const gridContainer = document.getElementById('library-books-container');
    const listContainer = document.getElementById('library-books-list');
    
    if (!viewButtons.length || !gridContainer || !listContainer) return;
    
    viewButtons.forEach(button => {
        button.addEventListener('click', function() {
            const viewType = this.getAttribute('data-view');
            
            viewButtons.forEach(btn => btn.classList.remove('active'));
            this.classList.add('active');
            
            if (viewType === 'grid') {
                gridContainer.style.display = 'grid';
                listContainer.style.display = 'none';
            } else {
                gridContainer.style.display = 'none';
                listContainer.style.display = 'block';
            }
        });
    });
}

// Gestion des filtres avancés (uniquement pour la bibliothèque)
function setupAdvancedFilters() {
    const categoryFilter = document.getElementById('category-filter');
    const sortFilter = document.getElementById('sort-filter');
    const searchInput = document.getElementById('library-search');
    
    if (!categoryFilter || !sortFilter) return;
    
    function applyFilters() {
        let filteredBooks = loadBooks();
        
        // Filtre par catégorie
        const categoryValue = categoryFilter.value;
        if (categoryValue !== 'all') {
            filteredBooks = filteredBooks.filter(book => 
                book.category === categoryValue
            );
        }
        
        // Filtre par recherche
        if (searchInput && searchInput.value) {
            const searchTerm = searchInput.value.toLowerCase();
            filteredBooks = filteredBooks.filter(book => 
                book.title.toLowerCase().includes(searchTerm) || 
                book.author.toLowerCase().includes(searchTerm) ||
                book.category.toLowerCase().includes(searchTerm) ||
                book.description.toLowerCase().includes(searchTerm)
            );
        }
        
        // Tri
        const sortValue = sortFilter.value;
        switch(sortValue) {
            case 'title':
                filteredBooks.sort((a, b) => a.title.localeCompare(b.title));
                break;
            case 'title-desc':
                filteredBooks.sort((a, b) => b.title.localeCompare(a.title));
                break;
            case 'author':
                filteredBooks.sort((a, b) => a.author.localeCompare(b.author));
                break;
            case 'new':
                filteredBooks.sort((a, b) => new Date(b.dateCreation) - new Date(a.dateCreation));
                break;
        }
        
        // Afficher les livres filtrés dans les deux vues
        displayBooks(filteredBooks, 'library-books-container');
        displayBooksList(filteredBooks, 'library-books-list');
    }
    
    // Écouter les changements de filtres
    [categoryFilter, sortFilter].forEach(filter => {
        filter.addEventListener('change', applyFilters);
    });
    
    // Écouter la recherche
    if (searchInput) {
        searchInput.addEventListener('input', applyFilters);
    }
    
    return applyFilters;
}

// Initialisation de la page bibliothèque
function initLibraryPage() {
    if (document.getElementById('library-books-container')) {
        const applyFilters = setupAdvancedFilters();
        setupViewToggle();
        
        // Appliquer les filtres initiaux
        if (applyFilters) {
            applyFilters();
        }
    }
}

// Menu mobile
function setupMobileMenu() {
    const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
    const mainNav = document.getElementById('main-nav');
    
    if (mobileMenuToggle && mainNav) {
        mobileMenuToggle.addEventListener('click', function() {
            mainNav.classList.toggle('active');
            
            const icon = this.querySelector('i');
            if (mainNav.classList.contains('active')) {
                icon.classList.remove('fa-bars');
                icon.classList.add('fa-times');
            } else {
                icon.classList.remove('fa-times');
                icon.classList.add('fa-bars');
            }
        });
    }
    
    // Fermer le menu mobile en cliquant sur un lien
    document.querySelectorAll('nav a').forEach(link => {
        link.addEventListener('click', function() {
            if (window.innerWidth <= 768) {
                mainNav.classList.remove('active');
                
                if (mobileMenuToggle) {
                    const icon = mobileMenuToggle.querySelector('i');
                    icon.classList.remove('fa-times');
                    icon.classList.add('fa-bars');
                }
            }
        });
    });
}

// Lancer l'initialisation quand la page est chargée
document.addEventListener('DOMContentLoaded', function() {
    // Initialiser le menu mobile
    setupMobileMenu();
    
    // Initialiser le carousel
    initCarousel();
    
    // Initialiser la page bibliothèque (uniquement si on est sur la page bibliothèque)
    initLibraryPage();
});

// Surveiller les changements dans le localStorage pour les livres admin (uniquement pour la bibliothèque)
window.addEventListener('storage', function(e) {
    if (e.key === 'admin_livres') {
        // Recharger les livres quand ils sont modifiés dans l'admin
        initLibraryPage();
    }
});

// Recharger les livres périodiquement (pour détecter les changements) - uniquement pour la bibliothèque
setInterval(() => {
    if (document.getElementById('library-books-container')) {
        const applyFilters = setupAdvancedFilters();
        if (applyFilters) {
            applyFilters();
        }
    }
}, 2000);