# Prednáškové bingo (Vercel + Supabase)

Statická stránka (`index.html`, žiadny build) + Supabase (účty, databáza, realtime).

1. Na supabase.com vytvor projekt. V **SQL Editor** spusti obsah `schema.sql`.
2. **Project Settings → API**: skopíruj *Project URL* a *anon public key* a vlož ich na začiatok skriptu v `index.html` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Anon kľúč je určený na verejné použitie, ochranu robia pravidlá RLS zo `schema.sql`.
3. **Authentication → Providers → Email**: vypni „Confirm email“ (**povinné**, prihlasuje sa menom a heslom bez e-mailu). Ak Supabase odmietne vymyslený e-mail ako neplatný, zmeň konštantu `DOM` v `index.html` na inú doménu.
4. Nasadenie: nahraj priečinok na GitHub a importuj ho vo Verceli (Framework: Other, bez build príkazu), alebo v priečinku spusti `npx vercel`.
5. **Authentication → URL Configuration**: pridaj svoju Vercel adresu do Site URL.
Funguje: účty (meno + heslo, bez e-mailu), profil (prezývka, avatar), učitelia s hláškami, miestnosti s kódom, realtime rebríček, nové kolo, konfety.

## Nastavenie cez CLI (config.toml)
Namiesto klikania v dashboarde:
```
npm i -g supabase
supabase init            # vytvorí supabase/config.toml, nahraď ho/uprav podľa priloženého
supabase login
supabase link --project-ref <TVOJ_PROJECT_REF>
supabase db push         # spustí supabase/migrations (tabuľky, RLS, realtime)
supabase config push     # nahrá auth nastavenia z config.toml (vypnuté Confirm email, dĺžka hesla, site_url)
```
Nahrá sa len to, čo `config push` podporuje (auth, realtime, API). `SUPABASE_URL` a anon kľúč vložíš do `index.html` ručne.
