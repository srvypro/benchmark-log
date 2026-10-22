# Benchmark Log

A field app for surveyors: a shared map of benchmarks, TBMs, control points and monuments with elevations, a level-run calculator with closure check, and a free on-phone reader for level-book pages.

Files:

- `index.html` is the whole app.
- `setup.sql` sets up the free Supabase database.

## Part 1: Put the site online (GitHub Pages, free)

1. Make a free account at github.com.
2. Click **+** (top right), then **New repository**. Name it `benchmark-log`, set it to **Public**, and click **Create repository**.
3. Click **uploading an existing file**, drag in `index.html`, `setup.sql` and `README.md`, then click **Commit changes**.
4. Open **Settings**, then **Pages**. Under "Branch" pick **main** and **/ (root)**, then click **Save**.
5. Wait a minute and refresh. Your site's address appears at the top, like `https://YOUR-NAME.github.io/benchmark-log/`.

The site now works, saving points on each phone only.

## Part 2: Connect the database so the crew shares points (Supabase, free)

1. Make a free account at supabase.com, then click **New project**. Pick a name, a database password (save it somewhere) and the region closest to you.
2. Open **SQL Editor**, then **New query**. Paste in everything from `setup.sql`, change `you@example.com` to your email, and click **Run**.
3. Open **Authentication**, then **URL Configuration**. Set **Site URL** to your GitHub Pages address, add the same address under **Redirect URLs**, and save.
4. Open **Project Settings**, then **API**. Copy the **Project URL** and the **anon public** key. These two are meant to be public. Your crew list is what keeps the data private.
5. In `index.html`, find `const CONFIG={supabaseUrl:"",supabaseKey:""};` near the bottom and paste the two values between the quotes. On GitHub, you can open the file and click the pencil icon to edit it.

Open the site, sign in with your email, and tap the link that arrives.

**Adding crew members:** in Supabase open **Table Editor**, then **crew**, then **Insert row**, and type their email in lowercase. They sign in with that email.

**Moving points from Part 1:** points you added before the database was connected stay on that phone. Use **Export CSV** before connecting, then **Import CSV** after you sign in.

## Good to know

- **Sign-in emails:** Supabase's free sign-in emails are limited to a few per hour, which is plenty for a crew because each phone stays signed in.
- **Maps:** street maps come from OpenStreetMap and satellite imagery from Esri, both free for light use.
- **Phone GPS** is good to a few meters. Use it to find a mark again, not for survey work.
