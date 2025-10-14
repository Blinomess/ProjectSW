// auth_service
async function register() {
    const username = document.getElementById('reg-username').value;
    const password = document.getElementById('reg-password').value;

    const res = await fetch(`/api/auth/register`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify({username, password})
    });
    const data = await res.json();
    alert(JSON.stringify(data));
}

async function login() {
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;

    const res = await fetch(`/api/auth/login`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify({username, password})
    });
    const data = await res.json();
    alert(JSON.stringify(data));
    if(data.session_id){
        localStorage.setItem('session_id', data.session_id);
        window.location.href = 'upload.html';
    }
}

async function checkSession() {
    const sessionId = localStorage.getItem('session_id');
    if (!sessionId) return false;
    
    try {
        const res = await fetch(`/api/auth/check-session?session_id=${sessionId}`);
        if (res.ok) {
            const data = await res.json();
            console.log('User ID:', data.user_id);
            return true;
        }
        else {
            console.log('Session invalid');
            localStorage.removeItem('session_id');
            return false;
        }
    } catch (error) {
        console.error('Session check failed:', error);
        return false;
    }
}

async function logout() {
    const sessionId = localStorage.getItem('session_id');
    if (sessionId) {
        try {
            await fetch(`/api/auth/logout`, {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({session_id: sessionId})
            });
        } catch (error) {
            console.error('Logout error:', error);
        }
        localStorage.removeItem('session_id');
    }
    window.location.href = 'index.html';
}
