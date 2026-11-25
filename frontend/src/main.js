// Frontend звертається лише до відносного шляху /api — nginx проксує його на Backend.
// Жодних адрес бекенду чи секретів у коді немає.
let token = null;

const $ = (sel) => document.querySelector(sel);

async function api(path, options = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`/api${path}`, { ...options, headers });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error || res.statusText);
  return body;
}

// Безпечне відображення: textContent замість innerHTML (захист від XSS)
async function loadBooks() {
  const books = await api('/books');
  const list = $('#books');
  list.replaceChildren();
  if (!books.length) {
    const li = document.createElement('li');
    li.className = 'muted';
    li.textContent = 'Поки що порожньо';
    list.append(li);
    return;
  }
  for (const b of books) {
    const li = document.createElement('li');
    const title = document.createElement('b');
    title.textContent = b.title;
    const meta = document.createElement('span');
    meta.className = 'muted';
    meta.textContent = ` (${b.city}, ${b.status})`;
    li.append(title, ` — ${b.author}`, meta);
    list.append(li);
  }
}

const formData = (form) => Object.fromEntries(new FormData(form));

$('#register').addEventListener('click', async () => {
  try {
    await api('/auth/register', { method: 'POST', body: JSON.stringify(formData($('#auth-form'))) });
    alert('Зареєстровано. Тепер увійдіть.');
  } catch (e) { alert(e.message); }
});

$('#auth-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  try {
    const { email, password } = formData(e.target);
    ({ token } = await api('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }));
    alert('Вхід виконано');
  } catch (err) { alert(err.message); }
});

$('#book-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  try {
    await api('/books', { method: 'POST', body: JSON.stringify(formData(e.target)) });
    e.target.reset();
    await loadBooks();
  } catch (err) { alert(err.message); }
});

fetch('/api/books').then(() => { $('#status').textContent = 'API доступне ✅'; loadBooks(); })
  .catch(() => { $('#status').textContent = 'API недоступне ❌'; });
