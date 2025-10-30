// auth.js - Gestion centralisée de l'authentification
const AUTH_KEYS = {
    CURRENT_USER: 'currentUser',
    USERS: 'users'
};

function getCurrentUser() {
    return JSON.parse(localStorage.getItem(AUTH_KEYS.CURRENT_USER));
}

function setCurrentUser(user) {
    localStorage.setItem(AUTH_KEYS.CURRENT_USER, JSON.stringify(user));
}

function getUsers() {
    return JSON.parse(localStorage.getItem(AUTH_KEYS.USERS)) || [];
}

function saveUsers(users) {
    localStorage.setItem(AUTH_KEYS.USERS, JSON.stringify(users));
}

function logout() {
    localStorage.removeItem(AUTH_KEYS.CURRENT_USER);
    window.location.reload();
}

function checkAuth() {
    return !!getCurrentUser();
}

function requireAuth(redirectUrl = 'home.html') {
    if (!checkAuth()) {
        window.location.href = redirectUrl;
    }
}