document.addEventListener('DOMContentLoaded', async function() {
    const isLoggedIn = await checkSession();
    
    if (!isLoggedIn) {
        alert('Please login first');
        window.location.href = 'index.html';
        return;
    }

    const main = document.querySelector('main');
    const header = document.querySelector('header');

    if (main && header) {
        main.style.display = 'block';
        header.style.display = 'none';
        console.log('User authorized, showing upload page');
    } else {
        console.error('main или header не найдены!');
    }
});

async function uploadFile() {
    const file = document.getElementById('fileInput').files[0];
    if(!file) return alert("Выберите файл!");

    const formData = new FormData();
    formData.append("file", file);

    const res = await fetch('http://localhost:8001/data/upload', {
        method: 'POST',
        body: formData
    });
    const data = await res.json();
    alert(JSON.stringify(data));
}