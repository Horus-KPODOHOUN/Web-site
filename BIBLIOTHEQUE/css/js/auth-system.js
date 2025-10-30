// Système d'authentification pour BiblioTech
class AuthSystem {
    constructor() {
        this.currentUser = null;
        this.users = JSON.parse(localStorage.getItem('biblioTech_users')) || [];
        this.init();
    }

    init() {
        this.checkAuthStatus();
        this.bindEvents();
    }

    bindEvents() {
        // Navigation entre les tabs
        document.querySelectorAll('.auth-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // Switch entre connexion et inscription
        document.querySelector('.switch-to-register')?.addEventListener('click', (e) => {
            e.preventDefault();
            this.switchTab('register');
        });

        document.querySelector('.switch-to-login')?.addEventListener('click', (e) => {
            e.preventDefault();
            this.switchTab('login');
        });

        // Soumission des formulaires
        document.getElementById('login-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        document.getElementById('register-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleRegister();
        });

        // Déconnexion
        document.getElementById('logout-btn')?.addEventListener('click', () => {
            this.logout();
        });
    }

    switchTab(tabName) {
        // Mettre à jour les tabs
        document.querySelectorAll('.auth-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabName);
        });

        // Afficher le bon formulaire
        document.querySelectorAll('.auth-form').forEach(form => {
            form.classList.toggle('active', form.id === `${tabName}-form`);
        });
    }

    handleLogin() {
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;

        if (!email || !password) {
            this.showNotification('Veuillez remplir tous les champs', 'error');
            return;
        }

        const user = this.users.find(u => u.email === email && u.password === password);
        
        if (user) {
            this.login(user);
        } else {
            this.showNotification('Email ou mot de passe incorrect', 'error');
        }
    }

    handleRegister() {
        const name = document.getElementById('register-name').value;
        const email = document.getElementById('register-email').value;
        const password = document.getElementById('register-password').value;
        const confirmPassword = document.getElementById('register-confirm').value;

        // Validation
        if (!name || !email || !password || !confirmPassword) {
            this.showNotification('Veuillez remplir tous les champs', 'error');
            return;
        }

        if (password !== confirmPassword) {
            this.showNotification('Les mots de passe ne correspondent pas', 'error');
            return;
        }

        if (password.length < 6) {
            this.showNotification('Le mot de passe doit contenir au moins 6 caractères', 'error');
            return;
        }

        if (this.users.find(u => u.email === email)) {
            this.showNotification('Cet email est déjà utilisé', 'error');
            return;
        }

        // Création du compte
        const newUser = {
            id: Date.now().toString(),
            name: name,
            email: email,
            password: password,
            createdAt: new Date().toISOString(),
            stats: {
                booksRead: 0,
                readingTime: 0,
                favorites: 0,
                inProgress: 0
            },
            recentBooks: [],
            favorites: []
        };

        this.users.push(newUser);
        localStorage.setItem('biblioTech_users', JSON.stringify(this.users));
        
        this.login(newUser);
        this.showNotification('Compte créé avec succès ! Bienvenue ' + name, 'success');
    }

    login(user) {
        this.currentUser = user;
        localStorage.setItem('biblioTech_currentUser', JSON.stringify(user));
        
        this.updateUI();
        this.showNotification(`Bienvenue ${user.name} !`, 'success');
        
        // Réinitialiser les formulaires
        document.getElementById('login-form').reset();
        document.getElementById('register-form').reset();
    }

    logout() {
        this.currentUser = null;
        localStorage.removeItem('biblioTech_currentUser');
        
        this.updateUI();
        this.showNotification('Vous avez été déconnecté', 'info');
    }

    checkAuthStatus() {
        const savedUser = localStorage.getItem('biblioTech_currentUser');
        if (savedUser) {
            this.currentUser = JSON.parse(savedUser);
        }
        this.updateUI();
    }

    updateUI() {
        const authSection = document.getElementById('auth-section');
        const userDashboard = document.getElementById('user-dashboard');
        const userGreeting = document.getElementById('user-greeting');
        const welcomeName = document.getElementById('welcome-name');
        const logoutBtn = document.getElementById('logout-btn');

        if (this.currentUser) {
            // Utilisateur connecté
            authSection.style.display = 'none';
            userDashboard.style.display = 'block';
            userGreeting.textContent = `Bonjour, ${this.currentUser.name}`;
            welcomeName.textContent = this.currentUser.name;
            logoutBtn.style.display = 'block';

            // Mettre à jour les statistiques
            this.updateUserStats();
            this.loadRecentBooks();
            this.loadRecommendedBooks();
        } else {
            // Utilisateur non connecté
            authSection.style.display = 'flex';
            userDashboard.style.display = 'none';
            userGreeting.textContent = '';
            logoutBtn.style.display = 'none';
        }
    }

    updateUserStats() {
        if (!this.currentUser) return;

        document.getElementById('books-read').textContent = this.currentUser.stats.booksRead;
        document.getElementById('reading-time').textContent = this.currentUser.stats.readingTime + 'h';
        document.getElementById('favorites').textContent = this.currentUser.stats.favorites;
        document.getElementById('in-progress').textContent = this.currentUser.stats.inProgress;
    }

    loadRecentBooks() {
        const container = document.getElementById('recent-books-container');
        if (!container) return;

        if (this.currentUser.recentBooks && this.currentUser.recentBooks.length > 0) {
            // Afficher les livres récents de l'utilisateur
            container.innerHTML = this.currentUser.recentBooks.map(bookId => {
                const book = this.getBookById(bookId);
                if (!book) return '';
                
                return `
                    <div class="book-card">
                        <div class="book-cover">
                            <img src="${book.cover}" alt="${book.title}">
                            <span class="pdf-badge">PDF</span>
                        </div>
                        <div class="book-info">
                            <div class="book-title">${book.title}</div>
                            <div class="book-author">${book.author}</div>
                            <div class="reading-options">
                                <button class="reading-option pdf" data-id="${book.id}">
                                    <i class="fas fa-book-open"></i> Continuer la lecture
                                </button>
                            </div>
                        </div>
                    </div>
                `;
            }).join('');
        } else {
            container.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 2rem; color: #666;">
                    <i class="fas fa-history" style="font-size: 3rem; margin-bottom: 1rem; display: block;"></i>
                    <h3>Aucun livre récent</h3>
                    <p>Commencez à explorer la bibliothèque pour voir vos livres récents ici.</p>
                </div>
            `;
        }
    }

    loadRecommendedBooks() {
        const container = document.getElementById('recommended-books-container');
        if (!container) return;

        // Charger quelques livres par défaut comme recommandations
        const defaultBooks = [
            {
                id: 1,
                title: "L'Étranger",
                author: "Albert Camus",
                cover: "https://via.placeholder.com/200x300/3498db/ffffff?text=L'Étranger",
                description: "Un roman philosophique qui explore l'absurdité de la vie."
            },
            {
                id: 2,
                title: "1984",
                author: "George Orwell", 
                cover: "https://via.placeholder.com/200x300/e74c3c/ffffff?text=1984",
                description: "Une dystopie célèbre sur un régime totalitaire."
            },
            {
                id: 3,
                title: "Le Petit Prince",
                author: "Antoine de Saint-Exupéry",
                cover: "https://via.placeholder.com/200x300/2ecc71/ffffff?text=Le+Petit+Prince",
                description: "Un conte poétique et philosophique."
            }
        ];

        container.innerHTML = defaultBooks.map(book => `
            <div class="book-card">
                <div class="book-cover">
                    <img src="${book.cover}" alt="${book.title}">
                    <span class="pdf-badge">PDF</span>
                </div>
                <div class="book-info">
                    <div class="book-title">${book.title}</div>
                    <div class="book-author">${book.author}</div>
                    <div class="book-description">${book.description}</div>
                    <div class="reading-options">
                        <button class="reading-option pdf" data-id="${book.id}">
                            <i class="fas fa-book-open"></i> Lire maintenant
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    }

    getBookById(bookId) {
        // Cette fonction devrait récupérer les livres depuis votre base de données
        // Pour l'instant, on retourne un livre fictif
        return {
            id: bookId,
            title: "Livre " + bookId,
            author: "Auteur",
            cover: "https://via.placeholder.com/200x300/ecf0f1/34495e?text=📚",
            description: "Description du livre"
        };
    }

    showNotification(message, type = 'info') {
        // Créer une notification temporaire
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            border-radius: 5px;
            color: white;
            z-index: 1001;
            transform: translateX(400px);
            transition: transform 0.3s ease;
            max-width: 300px;
        `;
        
        // Couleurs selon le type
        const colors = {
            success: '#2ecc71',
            error: '#e74c3c', 
            info: '#3498db',
            warning: '#f39c12'
        };
        
        notification.style.backgroundColor = colors[type] || colors.info;
        notification.innerHTML = `
            <span>${message}</span>
            <button class="close-notification" style="background: none; border: none; color: white; margin-left: 1rem; cursor: pointer;">&times;</button>
        `;
        
        document.body.appendChild(notification);
        
        // Animation d'entrée
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Fermeture
        notification.querySelector('.close-notification').addEventListener('click', () => {
            notification.style.transform = 'translateX(400px)';
            setTimeout(() => notification.remove(), 300);
        });
        
        // Fermeture automatique après 5 secondes
        setTimeout(() => {
            if (notification.parentNode) {
                notification.style.transform = 'translateX(400px)';
                setTimeout(() => {
                    if (notification.parentNode) {
                        notification.remove();
                    }
                }, 300);
            }
        }, 5000);
    }
}

// Initialiser le système d'authentification
const authSystem = new AuthSystem();