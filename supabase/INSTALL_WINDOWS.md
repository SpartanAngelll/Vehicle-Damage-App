# Installing Supabase CLI on Windows

## ❌ Don't Use: `npm install -g supabase`

Supabase CLI no longer supports global npm installation. Use one of these methods instead:

## ✅ Method 1: Local Install (Easiest - Recommended)

Install as a dev dependency in your project:

```powershell
npm install supabase --save-dev
```

Then use with `npx`:

```powershell
npx supabase login
npx supabase db push
```

**Pros:**
- ✅ No additional tools needed
- ✅ Version locked to your project
- ✅ Works immediately

**Cons:**
- Need to use `npx` prefix for commands

---

## ✅ Method 2: Scoop (Best for Global Install)

Scoop is a Windows package manager. Install once, use everywhere.

### Step 1: Install Scoop (if not installed)

```powershell
# Run in PowerShell (as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### Step 2: Add Supabase Bucket

```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
```

### Step 3: Install Supabase CLI

```powershell
scoop install supabase
```

### Step 4: Verify Installation

```powershell
supabase --version
```

**Pros:**
- ✅ Global installation
- ✅ Easy updates: `scoop update supabase`
- ✅ No `npx` prefix needed

**Cons:**
- Requires Scoop installation

---

## ✅ Method 3: Direct Download

1. Go to: https://github.com/supabase/cli/releases
2. Download latest `supabase_windows_amd64.zip`
3. Extract to a folder (e.g., `C:\Tools\supabase`)
4. Add folder to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add the folder path
5. Restart PowerShell
6. Verify: `supabase --version`

**Pros:**
- ✅ No package manager needed
- ✅ Full control

**Cons:**
- Manual updates required
- PATH configuration needed

---

## Quick Test

After installation, test with:

```powershell
# If local install:
npx supabase --version

# If global install:
supabase --version
```

---

## Recommended: Use Local Install

For this project, we recommend **Method 1 (Local Install)** because:
- ✅ No additional setup
- ✅ Version consistency across team
- ✅ Works with our automated scripts

The setup scripts (`setup.ps1` and `setup.sh`) will automatically detect and use local installation if available.

