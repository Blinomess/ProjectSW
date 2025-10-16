document.addEventListener('DOMContentLoaded', async function() {
    const isLoggedIn = await checkSession();

    if (!isLoggedIn) {
        alert('Пожалуйста, войдите в систему!');
        window.location.href = 'index.html';
        return;
    }

    const main = document.querySelector('main');

    if (main) {
        main.style.display = 'block';
    }

    await updateFileList();

    const searchInput = document.getElementById('fileSearchInput');
    function debounce(fn, delay) {
    let timer;
    return function(...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
    }

    if (searchInput) {
        searchInput.addEventListener('input', debounce(async (e) => {
            const query = e.target.value.trim().toLowerCase();
            await updateFileList(query);
        }, 300));
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
        const response = await fetch(`/api/processing/analyze/${filename}`);
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
            div.style.margin = '10px';
            div.style.borderRadius = '8px';
            div.style.background = '#1e1e1e';
            div.style.boxSizing = 'border-box';
            div.style.display = 'flex';
            div.style.flexDirection = 'column';
            div.style.justifyContent = 'space-between';
            div.style.alignItems='center';
            div.style.height='450px';
            div.style.minHeight='300px';
            div.style.width='300px';


            const info = document.createElement('p');
            const descrptnShow = file.description?.trim() || "Нет";
            info.textContent = `Имя: ${file.title}, Тип: ${file.filetype}, Описание: ${descrptnShow}`;
            info.style.fontWeight = 'bold';
            div.appendChild(info);

            if (file.filetype === 'csv') {
                const previewContainer = document.createElement('div');
                previewContainer.style.marginTop = '10px';
                previewContainer.style.maxWidth = '100%';

                const previewTitle = document.createElement('p');
                previewTitle.textContent = 'Первые строки и статистика:';
                previewTitle.style.fontWeight = 'bold';
                previewContainer.appendChild(previewTitle);

                const previewContent = document.createElement('pre');
                previewContent.style.background = '#000000ff';
                previewContent.style.padding = '10px';
                previewContent.style.borderRadius = '5px';
                previewContent.style.overflowX = 'auto';
                previewContainer.appendChild(previewContent);

                const statsContainer = document.createElement('div');
                statsContainer.style.marginTop = '10px';
                previewContainer.appendChild(statsContainer);

                div.appendChild(previewContainer);

                getCsvPreview(file.filename).then(data => {
                    previewContent.textContent = data.preview;
                    statsContainer.innerHTML = `
                        <p><b>Количество столбцов:</b> ${data.columns}</p>
                        <p><b>Суммы по столбцам:</b> ${(data.sums || []).join(', ')}</p>
                        <p><b>Средние по столбцам:</b> ${data.averages.map(a => a.toFixed(2)).join(', ')}</p>
                        <p><b>Максимальные значения по столбцам:</b> ${(data.max_values || []).join(', ')}</p>
                    `;
                });
            }

            if (file.filetype === 'photo') {
                const div_img= document.createElement('div');
                div_img.classList.add('div_img');
                div_img.style.maxHeight='300px';
                div_img.style.overflow='auto';
                div_img.style.margin='10px 0';
                const img = document.createElement('img');
                img.src = `/api/data/download/${file.filename}`;
                img.alt = file.filename;
                div_img.appendChild(img);
                div.appendChild(div_img);
            }

            const downloadBtn = document.createElement('button');
            downloadBtn.classList.add('card_btn');
            downloadBtn.textContent = 'Скачать';
            downloadBtn.onclick = () => {
                const link = document.createElement('a');
                link.href = `/api/data/download/${file.filename}`;
                link.download = file.filename;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            };
            

            const deleteBtn = document.createElement('button');
            deleteBtn.classList.add('card_btn');
            deleteBtn.textContent = 'Удалить';
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
            }

            const buttonsContainer = document.createElement('div');
            buttonsContainer.classList.add('buttons-container');

            buttonsContainer.appendChild(downloadBtn);
            buttonsContainer.appendChild(deleteBtn);

            div.appendChild(buttonsContainer);

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


function showSection(section) {
    const uploadSection = document.getElementById('upload_section');
    const searchSection = document.getElementById('search_section');

    if (section === 'upload') {
        uploadSection.style.display = 'flex';
        searchSection.style.display = 'none';
    } else if (section === 'search') {
        uploadSection.style.display = 'none';
        searchSection.style.display = 'flex';
    }
}