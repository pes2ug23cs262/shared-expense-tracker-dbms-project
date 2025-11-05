# 💰 Expense Sharing Tracker - Complete Project

A full-stack web application for tracking and managing shared expenses among friends, roommates, or groups. Built with **Streamlit** (Frontend), **Flask** (API Backend), and **MySQL** (Database).

## ✨ Features

### Core Functionality
- **User Authentication**: Secure login/registration with bcrypt hashing
- **Group Management**: Create expense groups and manage members
- **Expense Tracking**: Add expenses with equal or custom split
- **Balance Calculation**: Automatic balance tracking between users
- **Payment Settlement**: Record payments and settle debts
- **Expense History**: View complete transaction history
- **Group Analytics**: Get summaries and statistics

### Technical Features
- **REST API**: Complete Flask API with JWT authentication
- **Database Triggers**: Auto-validate data integrity
- **Stored Procedures**: Complex business logic at database level
- **Session Management**: Secure user sessions in Streamlit
- **Error Handling**: Comprehensive error handling and validation

## 📋 Project Structure

```
expense-tracker/
├── streamlit_app.py          # Main Streamlit frontend
├── flask_backend.py          # Flask REST API server
├── config.py                 # Configuration management
├── requirements.txt          # Python dependencies
├── database/
│   ├── DDL.sql              # Table creation
│   ├── DML.sql              # Sample data
│   ├── functions.sql        # MySQL functions (12 total)
│   ├── procedures.sql       # Stored procedures (8 total)
│   └── triggers.sql         # Database triggers (7 total)
├── integration_guide.md      # Detailed setup guide
├── .env.example              # Environment variables template
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- MySQL 8.0+
- Git

### 1. Clone & Setup
```bash
# Clone repository
git clone <repository-url>
cd expense-tracker

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Database Setup
```bash
# Open MySQL client
mysql -u root -p

# Run SQL files in order
source database/DDL.sql;
source database/functions.sql;
source database/procedures.sql;
source database/triggers.sql;
source database/DML.sql;  # Optional: sample data

# Verify
USE expense_sharing_tracker;
SHOW TABLES;
```

### 3. Configure Application
```bash
# Copy and edit .env file
cp .env.example .env

# Edit .env with your credentials:
# DB_HOST=localhost
# DB_USER=root
# DB_PASSWORD=your_password
# JWT_SECRET_KEY=your_secret_key
```

### 4. Run Application

**Terminal 1: Start Flask Backend**
```bash
python flask_backend.py
# API runs on http://localhost:5000
```

**Terminal 2: Start Streamlit Frontend**
```bash
streamlit run streamlit_app.py
# Frontend opens at http://localhost:8501
```

## 📖 Usage Guide

### For End Users

#### 1. Registration & Login
- Click "Register" tab and create account
- Use credentials to login
- You're now ready to use the app!

#### 2. Create Group
- Go to "Groups" → "Create Group"
- Enter group name and description
- Click "Create Group"

#### 3. Add Members
- In Groups tab, expand group
- Enter member's email
- Click "Add Member"

#### 4. Add Expenses
1. Go to "Add Expense"
2. Select group
3. Enter expense description and amount
4. Choose split type:
   - **Equal Split**: Automatically divides among all members
   - **Custom Split**: Manually specify each person's share
5. Click "Add Expense"

#### 5. View & Settle Payments
- Go to "Payments"
- See your balances (red = you owe, green = owed to you)
- Enter payment details and click "Record Payment"

#### 6. View Reports
- Go to "Reports"
- Select group to see:
  - Member count
  - Expense count
  - Total spent
  - Expense history

### For Developers

#### REST API Examples

**Get Groups**
```bash
curl -X GET http://localhost:5000/api/groups \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Add Expense (Equal Split)**
```bash
curl -X POST http://localhost:5000/api/groups/1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Dinner",
    "amount": 1200.00,
    "split_type": "equal"
  }'
```

**Add Expense (Custom Split)**
```bash
curl -X POST http://localhost:5000/api/groups/1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Movie tickets",
    "amount": 500.00,
    "split_type": "custom",
    "shares": [
      {"user_id": 1, "amount": 250.00},
      {"user_id": 2, "amount": 250.00}
    ]
  }'
```

## 🗄️ Database Schema

### Tables (7 total)
1. **users** - User accounts and authentication
2. **expense_groups** - Group definitions
3. **members** - Group membership
4. **expenses** - Expense transactions
5. **expense_shares** - How expenses are split
6. **balances** - Who owes whom
7. **payments** - Payment history

### Functions (12 total)
- `get_total_user_owes()` - Total user owes in group
- `get_total_owed_to_user()` - Total owed to user
- `get_user_net_balance()` - Net balance for user
- `get_user_total_spending()` - Total user spent
- `get_user_total_share()` - User's share in expenses
- `is_group_member()` - Check membership
- `get_group_total_expenses()` - Group total spent
- `get_group_member_count()` - Count members
- `get_balance_between_users()` - Balance between two users
- `get_user_expense_count()` - Count user's expenses
- `is_expense_in_group()` - Verify expense in group
- `get_user_share_in_expense()` - User's share in specific expense

### Procedures (8 total)
- `add_expense_equal_split()` - Add expense with equal split
- `add_expense_custom_split()` - Add expense with custom split
- `settle_balance()` - Record payment
- `get_user_balance_summary()` - Get user's balance info
- `get_group_summary()` - Get group statistics
- `get_user_expenses_in_group()` - Get user's expenses
- `simplify_group_debts()` - Calculate simplified settlement
- `delete_expense()` - Remove expense and update balances

### Triggers (7 total)
- `after_group_insert` - Auto-add creator as member
- `after_expense_share_insert` - Validate shares
- `after_expense_share_update` - Validate share updates
- `after_expense_share_insert_update_balance` - Update balances on expense
- `after_payment_insert` - Reduce balance on payment
- `before_expense_insert` - Verify creator is member
- `before_expense_share_insert` - Verify user is member
- `before_payment_insert` - Verify users are members

## 🔐 Security

### Implemented
✅ Password hashing with bcrypt
✅ JWT authentication for API
✅ Database constraints and validation
✅ SQL injection prevention (parameterized queries)
✅ CORS protection
✅ Session management
✅ Trigger-based data validation

### Recommendations for Production
- Use environment variables for secrets
- Enable HTTPS/SSL
- Implement rate limiting
- Add logging and monitoring
- Use connection pooling
- Regular database backups
- Implement 2FA
- Add audit logging

## 🛠️ Configuration

### .env File
```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=expense_sharing_tracker
DB_USER=root
DB_PASSWORD=your_password

# Flask
FLASK_ENV=development
SECRET_KEY=your_secret_key
JWT_SECRET_KEY=your_jwt_secret

# API
API_BASE_URL=http://localhost:5000

# Cors
CORS_ORIGINS=http://localhost:8501,http://localhost:3000
```

### config.py
All configuration constants, error messages, feature flags, etc.

## 📊 API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Register user |
| POST | `/api/auth/login` | User login |
| GET | `/api/groups` | Get user's groups |
| POST | `/api/groups` | Create group |
| GET | `/api/groups/<id>/members` | Get group members |
| POST | `/api/groups/<id>/members` | Add member |
| GET | `/api/groups/<id>/expenses` | Get expenses |
| POST | `/api/groups/<id>/expenses` | Add expense |
| GET | `/api/groups/<id>/balance` | Get user balance |
| GET | `/api/groups/<id>/summary` | Get group summary |
| GET | `/api/groups/<id>/payments` | Get payments |
| POST | `/api/groups/<id>/payments` | Record payment |
| GET | `/api/health` | Health check |

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Check MySQL is running
# Windows: Check Services
# macOS: brew services list
# Linux: sudo systemctl status mysql

# Verify credentials in config
# Check database exists
mysql -u root -p -e "SHOW DATABASES;"
```

### Port Already in Use
```bash
# Flask on different port:
# Edit flask_backend.py: app.run(port=5001)

# Streamlit on different port:
streamlit run streamlit_app.py --server.port 8502
```

### Module Not Found
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # or venv\Scripts\activate

# Reinstall dependencies
pip install -r requirements.txt
```

## 📚 Learning Resources

- [Streamlit Documentation](https://docs.streamlit.io)
- [Flask Documentation](https://flask.palletsprojects.com)
- [MySQL Reference](https://dev.mysql.com/doc)
- [JWT Guide](https://jwt.io)
- [REST API Best Practices](https://restfulapi.net)

## 🎯 Future Enhancements

- [ ] Mobile app (React Native)
- [ ] Expense categories
- [ ] Recurring expenses
- [ ] Email notifications
- [ ] Export to PDF/CSV
- [ ] Multi-currency support
- [ ] Analytics dashboard
- [ ] Budget tracking
- [ ] Bill splitting algorithms
- [ ] User profiles with avatars

## 📝 Database Migration

If modifying schema:
1. Create migration script in `database/migrations/`
2. Test with backup data
3. Document changes
4. Run on production backup first

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 📄 License

Educational Project - Free to use and modify

## 👨‍💻 Author

Created as a DBMS project for learning purposes.

---

## ⚡ Quick Reference

**Start Everything:**
```bash
# Terminal 1: MySQL (if needed)
# Terminal 2: Flask
python flask_backend.py

# Terminal 3: Streamlit
streamlit run streamlit_app.py
```

**Access Points:**
- 🌐 Frontend: http://localhost:8501
- 🔌 API: http://localhost:5000
- 🗄️ Database: localhost:3306

**Key Files:**
- Frontend UI: `streamlit_app.py`
- Backend API: `flask_backend.py`
- Configuration: `config.py`
- Database: `database/` folder

**Debugging:**
- Check MySQL: `mysql -u root -p`
- Check API: `curl http://localhost:5000/api/health`
- Streamlit logs: Check terminal
- Flask logs: Check terminal

---

**Ready to track expenses? Start with the Quick Start section! 🚀**
