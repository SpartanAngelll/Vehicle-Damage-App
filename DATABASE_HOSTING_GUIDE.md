# Database Hosting Guide

This guide will help you get your PostgreSQL database hosted again. Choose the option that best fits your needs.

## 🎯 Quick Overview

Your app uses PostgreSQL with:
- **Database name**: `vehicle_damage_payments`
- **Default user**: `postgres`
- **Default password**: `#!Startpos12` (from docker-compose-postgres.yml)
- **Port**: `5432`

---

## Option 1: Docker Compose (Recommended - Easiest)

This is the simplest way to get your database running quickly.

### Prerequisites
- Docker Desktop installed and running
- Docker Compose installed (comes with Docker Desktop)

### Steps

1. **Navigate to your project directory**
   ```bash
   cd C:\Users\samue\vehicle_damage_app
   ```

2. **Start the PostgreSQL container**
   ```bash
   docker-compose -f docker-compose-postgres.yml up -d
   ```

3. **Verify the database is running**
   ```bash
   docker ps
   ```
   You should see `vehicle_damage_postgres` container running.

4. **Set up the database schema**
   ```bash
   # Connect to the database and run the schema
   docker exec -i vehicle_damage_postgres psql -U postgres -d vehicle_damage_payments < database/complete_schema.sql
   ```

5. **Test the connection**
   ```bash
   docker exec -it vehicle_damage_postgres psql -U postgres -d vehicle_damage_payments
   ```
   Then run: `\dt` to see all tables, and `\q` to exit.

### To Stop the Database
```bash
docker-compose -f docker-compose-postgres.yml down
```

### To Start Again Later
```bash
docker-compose -f docker-compose-postgres.yml up -d
```

---

## Option 2: Local PostgreSQL Installation

If you prefer a local PostgreSQL installation instead of Docker.

### Prerequisites
- PostgreSQL installed on your Windows machine
- PostgreSQL service running

### Steps

1. **Verify PostgreSQL is installed**
   ```bash
   psql --version
   ```

2. **Start PostgreSQL service** (if not running)
   ```powershell
   # Run PowerShell as Administrator
   Start-Service postgresql-x64-17
   # Or use Services app: search for "PostgreSQL" and start it
   ```

3. **Create the database** (if it doesn't exist)
   ```bash
   psql -U postgres -c "CREATE DATABASE vehicle_damage_payments;"
   ```
   Enter password when prompted: `#!Startpos12`

4. **Set up the database schema**
   ```bash
   psql -U postgres -d vehicle_damage_payments -f database/complete_schema.sql
   ```

5. **Configure network access** (if needed for mobile devices)
   ```powershell
   # Run as Administrator
   .\configure_postgres.ps1
   ```

6. **Test the connection**
   ```bash
   psql -U postgres -d vehicle_damage_payments
   ```
   Then run: `\dt` to see all tables, and `\q` to exit.

---

## Option 3: Cloud-Hosted PostgreSQL

For production or remote access, consider cloud hosting options:

### Popular Options:
- **Supabase** (Free tier available)
- **Neon** (Serverless PostgreSQL)
- **Railway** (Easy deployment)
- **AWS RDS** (Enterprise)
- **Google Cloud SQL** (Enterprise)
- **Azure Database for PostgreSQL** (Enterprise)

### Steps for Cloud Hosting:

1. **Sign up for a cloud PostgreSQL service**

2. **Create a new PostgreSQL database**
   - Database name: `vehicle_damage_payments`
   - Note down: host, port, username, password

3. **Update your backend environment variables**
   Create a `.env` file in the `backend/` directory:
   ```env
   POSTGRES_HOST=your-cloud-host.com
   POSTGRES_PORT=5432
   POSTGRES_USER=your_username
   POSTGRES_PASSWORD=your_password
   POSTGRES_DB=vehicle_damage_payments
   ```

4. **Set up the database schema**
   ```bash
   # Using psql with connection string
   psql "postgresql://username:password@host:port/vehicle_damage_payments" -f database/complete_schema.sql
   
   # Or using pgAdmin or your cloud provider's SQL editor
   # Copy and paste the contents of database/complete_schema.sql
   ```

5. **Update your backend server configuration**
   The `backend/server.js` already reads from environment variables, so it should work automatically.

---

## 🔧 Configure Your Backend Server

After your database is hosted, configure your backend:

### For Local/Docker Setup:

1. **Set environment variables** (optional, defaults are already set)
   Create `backend/.env`:
   ```env
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5432
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=#!Startpos12
   POSTGRES_DB=vehicle_damage_payments
   PORT=3000
   ```

2. **Start your backend server**
   ```bash
   cd backend
   npm install  # If you haven't already
   node server.js
   ```

3. **Test the connection**
   ```bash
   curl http://localhost:3000/api/health
   ```

### For Cloud Setup:

1. **Create `backend/.env`** with your cloud database credentials:
   ```env
   POSTGRES_HOST=your-cloud-host.com
   POSTGRES_PORT=5432
   POSTGRES_USER=your_username
   POSTGRES_PASSWORD=your_password
   POSTGRES_DB=vehicle_damage_payments
   PORT=3000
   ```

2. **Start your backend server**
   ```bash
   cd backend
   node server.js
   ```

---

## ✅ Verification Checklist

After setting up your database, verify everything works:

- [ ] Database container/service is running
- [ ] Can connect to database using `psql`
- [ ] Database schema is created (check with `\dt` in psql)
- [ ] Backend server starts without errors
- [ ] Health check endpoint responds: `http://localhost:3000/api/health`
- [ ] Can query database from backend (test an API endpoint)

---

## 🐛 Troubleshooting

### Docker Issues

**Container won't start:**
```bash
# Check if port 5432 is already in use
netstat -ano | findstr :5432

# Stop any existing PostgreSQL services
docker-compose -f docker-compose-postgres.yml down
docker-compose -f docker-compose-postgres.yml up -d
```

**Can't connect to database:**
```bash
# Check container logs
docker logs vehicle_damage_postgres

# Restart container
docker-compose -f docker-compose-postgres.yml restart
```

### Local PostgreSQL Issues

**Service won't start:**
- Open Services app (Win+R → `services.msc`)
- Find PostgreSQL service
- Right-click → Start
- Check error logs in PostgreSQL data directory

**Connection refused:**
- Verify PostgreSQL is listening on port 5432
- Check Windows Firewall settings
- Ensure `pg_hba.conf` allows your connection

### Backend Connection Issues

**"Connection refused" error:**
- Verify database is running
- Check `POSTGRES_HOST` matches your setup (localhost for local/Docker)
- Verify port 5432 is correct

**"Authentication failed" error:**
- Check username and password match
- For Docker: use password from `docker-compose-postgres.yml`
- For local: use your PostgreSQL installation password

**"Database does not exist" error:**
- Create the database: `CREATE DATABASE vehicle_damage_payments;`
- Run the schema setup script

---

## 📝 Quick Reference Commands

### Docker Commands
```bash
# Start database
docker-compose -f docker-compose-postgres.yml up -d

# Stop database
docker-compose -f docker-compose-postgres.yml down

# View logs
docker logs vehicle_damage_postgres

# Connect to database
docker exec -it vehicle_damage_postgres psql -U postgres -d vehicle_damage_payments

# Run schema
docker exec -i vehicle_damage_postgres psql -U postgres -d vehicle_damage_payments < database/complete_schema.sql
```

### PostgreSQL Commands
```bash
# Connect to database
psql -U postgres -d vehicle_damage_payments

# List all tables
\dt

# Exit psql
\q

# Run SQL file
psql -U postgres -d vehicle_damage_payments -f database/complete_schema.sql
```

---

## 🚀 Next Steps

Once your database is hosted:

1. **Update your Flutter app** to point to the correct backend URL
2. **Test the full workflow** - create users, bookings, payments
3. **Set up backups** (especially for production)
4. **Monitor database performance**
5. **Configure SSL** for production deployments

---

## 📞 Need Help?

If you encounter issues:
1. Check the container/service logs
2. Verify all environment variables are set correctly
3. Test database connection directly with `psql`
4. Check backend server logs for specific error messages

Good luck! 🎉


