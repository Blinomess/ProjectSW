document.addEventListener('DOMContentLoaded', async function() {
    const isLoggedIn = await checkSession();

    if (!isLoggedIn) {
        alert('Пожалуйста, войдите в систему!');
        window.location.href = 'index.html';
        return;
    }

    const main = document.querySelector('main');
    const header = document.querySelector('header');

    if (main && header) {
        main.style.display = 'block';
        header.style.display = 'none';
    }

    await updateFileList();

    const searchInput = document.getElementById('fileSearchInput');
    if (searchInput) {
        searchInput.addEventListener('input', async (e) => {
            const query = e.target.value.trim().toLowerCase();
            await updateFileList(query);
        });
    }

    const searchBtn = document.getElementById('fileSearch');
    if (searchBtn) {
        searchBtn.addEventListener('click', async () => {
            const query = searchInput.value.trim().toLowerCase();
            await updateFileList(query);
        });
    }
});

async function uploadFile() {
    const file = document.getElementById('fileInput').files[0];
    if (!file) return alert("Выберите файл!");

    const fileName = document.getElementById('fileNameInput').value || file.name;
    const fileDesc = document.getElementById('fileDescInput').value || "";

    const formData = new FormData();
    formData.append("file", file);
    formData.append("title", fileName);
    formData.append("description", fileDesc);

    try {
        const res = await fetch('/api/data/upload', {
            method: 'POST',
            body: formData
        });

        if (!res.ok) throw new Error(`Ошибка ${res.status}`);
        const data = await res.json();
        alert(`Файл загружен: ${JSON.stringify(data)}`);

        await updateFileList();
    } catch (err) {
        console.error(err);
        alert('Ошибка при загрузке файла');
    }
}

async function getCsvPreview(filename) {
    try {
        const response = await fetch(`/api/data/preview/${filename}`);
        if (!response.ok) throw new Error(`Ошибка ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error('Ошибка при получении preview CSV:', error);
        return { 
            preview: 'Не удалось загрузить preview', 
            columns: 0, 
            sums: [], 
            averages: [], 
            max_values: [] 
        };
    }
}

async function updateFileList(searchQuery = '') {
    try {
        const response = await fetch('/api/data/files');
        const files = await response.json();
        const fileList = document.getElementById('fileList');
        fileList.innerHTML = '';

        const filteredFiles = files.filter(f => 
            f.title.toLowerCase().includes(searchQuery) || 
            f.filename.toLowerCase().includes(searchQuery)
        );

        filteredFiles.forEach(file => {
            const div = document.createElement('div');
            div.classList.add('file-item');
            div.style.border = '1px solid #ccc';
            div.style.padding = '10px';
            div.style.marginBottom = '10px';
            div.style.borderRadius = '8px';
            div.style.background = '#fdfdfd';

            const info = document.createElement('p');
            const descrptnShow = file.description && file.description.trim() !== "" ? file.description : "Нет";
            info.textContent = `Имя: ${file.title}, Тип: ${file.filetype}, Описание: ${descrptnShow}`;
            info.style.fontWeight = 'bold';
            div.appendChild(info);

            if (file.filetype === 'csv') {
                const previewContainer = document.createElement('div');
                previewContainer.style.marginTop = '10px';

                const previewTitle = document.createElement('p');
                previewTitle.textContent = 'Первые строки и статистика:';
                previewTitle.style.fontWeight = 'bold';
                previewContainer.appendChild(previewTitle);

                const previewContent = document.createElement('pre');
                previewContent.style.background = '#f5f5f5';
                previewContent.style.padding = '10px';
                previewContent.style.borderRadius = '5px';
                previewContent.style.overflowX = 'auto';
                previewContent.textContent = 'Загрузка...';
                previewContainer.appendChild(previewContent);

                const statsContainer = document.createElement('div');
                statsContainer.style.marginTop = '10px';
                previewContainer.appendChild(statsContainer);

                div.appendChild(previewContainer);

                getCsvPreview(file.filename).then(data => {
                    previewContent.textContent = data.preview;
                    statsContainer.innerHTML = `
                        <p><b>Количество столбцов:</b> ${data.columns}</p>
                        <p><b>Суммы по столбцам:</b> ${data.sums.join(', ')}</p>
                        <p><b>Средние по столбцам:</b> ${data.averages.map(a => a.toFixed(2)).join(', ')}</p>
                        <p><b>Максимальные значения по столбцам:</b> ${data.max_values.join(', ')}</p>
                    `;
                });
            }

            if (file.filetype === 'photo') {
                const img = document.createElement('img');
                img.src = `/api/data/download/${file.filename}`;
                img.alt = file.filename;
                img.style.maxWidth = '200px';
                div.appendChild(img);
            }

            const downloadBtn = document.createElement('button');
            downloadBtn.textContent = 'Скачать';
            downloadBtn.style.display = 'block';
            downloadBtn.style.marginTop = '5px';
            downloadBtn.onclick = () => {
                const link = document.createElement('a');
                link.href = `/api/data/download/${file.filename}`;
                link.download = file.filename;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            };
            div.appendChild(downloadBtn);

            const deleteBtn = document.createElement('button');
            deleteBtn.textContent = 'Удалить';
            deleteBtn.style.marginTop = '5px';
            deleteBtn.onclick = async () => {
                const confirmDelete = confirm(`Вы уверены, что хотите удалить ${file.filename}?`);
                if (!confirmDelete) return;

                const res = await fetch(`/api/data/files/${file.filename}`, { method: 'DELETE' });
                if (res.ok) {
                    alert(`${file.filename} удалён`);
                    updateFileList(searchQuery);
                } else {
                    const errorData = await res.json();
                    alert(`Ошибка: ${errorData.detail}`);
                }
            };
            div.appendChild(deleteBtn);

            fileList.appendChild(div);
        });

        if (filteredFiles.length === 0) {
            fileList.textContent = 'Файлы не найдены';
        }

    } catch (err) {
        console.error(err);
        document.getElementById('fileList').textContent = 'Ошибка при загрузке файлов';
    }
}
