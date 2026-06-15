# Flask TODO DevOps Final Project

## 1. סקירת הפרויקט

זהו פרויקט גמר פשוט ב-DevOps.
הבסיס של הפרויקט הוא אפליקציית TODO קטנה שנכתבה עם Flask.

המטרה היא לא לבנות אפליקציה גדולה ומורכבת, אלא להראות תהליך DevOps מלא סביב אפליקציה פשוטה:

- הרצת אפליקציה
- חיבור למסד נתונים
- בדיקות אוטומטיות
- Docker
- Docker Compose
- GitHub Actions
- בניית Docker image
- העלאה ל-Docker Hub

## 2. מטרת הפרויקט

מטרת הפרויקט היא להראות איך מפתח עובד בצורה מסודרת:

1. כותבים קוד.
2. שומרים את הקוד ב-GitHub.
3. GitHub Actions מריץ בדיקות.
4. אם הבדיקות עוברות, נבנה Docker image.
5. ה-image נשלח ל-Docker Hub.

בהמשך הפרויקט מתוכנן גם שלב Deployment לשרת AWS EC2.

## 3. ארכיטקטורה

הארכיטקטורה של האפליקציה:

```text
User -> Flask -> SQLAlchemy -> MySQL
```

הסבר פשוט:

- המשתמש נכנס לאפליקציה בדפדפן.
- Flask מקבל את הבקשה.
- SQLAlchemy מדבר עם מסד הנתונים.
- MySQL שומר את משימות ה-TODO.

## 4. זרימת DevOps

זרימת ה-DevOps בפרויקט:

```text
Developer -> GitHub -> GitHub Actions -> pytest -> Docker build -> Docker Hub
```

הסבר פשוט:

- המפתח עושה שינוי בקוד.
- הקוד נשלח ל-GitHub.
- GitHub Actions מתחיל לרוץ אוטומטית.
- pytest מריץ בדיקות.
- Docker בונה image לאפליקציה.
- אם הכל מצליח, ה-image נשלח ל-Docker Hub.

## 5. הסבר קבצים

### app.py

הקובץ הראשי של אפליקציית Flask.
בקובץ הזה נמצאים:

- יצירת האפליקציה
- הגדרת החיבור למסד הנתונים
- מודל `Todo`
- routes כמו `/`, `/add`, `/update`, `/delete`
- route בריאות: `/health`

### requirements.txt

רשימת ספריות Python שהפרויקט צריך.
GitHub Actions וגם Docker משתמשים בקובץ הזה כדי להתקין dependencies.

### Dockerfile

קובץ שמגדיר איך לבנות Docker image לאפליקציית Flask.
הוא מתקין את התלויות ומריץ את `app.py`.

### docker-compose.yml

קובץ שמריץ כמה containers יחד:

- container של Flask
- container של MySQL

כך אפשר להריץ את כל המערכת מקומית בפקודה אחת.

### .github/workflows/ci.yml

קובץ GitHub Actions.
הוא מגדיר את תהליך ה-CI:

- checkout לקוד
- התקנת Python
- התקנת requirements
- הרצת pytest
- בניית Docker image
- התחברות ל-Docker Hub עם GitHub Secrets
- העלאת image ל-Docker Hub

### tests/test_health.py

בדיקה פשוטה עם pytest.
הבדיקה בודקת שה-route `/health` מחזיר תשובה תקינה.

### templates/

תיקייה של קבצי HTML.
Flask משתמש בקבצים האלה כדי להציג עמודים למשתמש.

### static/

תיקייה לקבצים סטטיים כמו CSS ותמונות.

### db/

תיקייה שקשורה להגדרות MySQL.

## 6. איך להריץ מקומית עם Docker Compose

מתוך תיקיית הפרויקט מריצים:

```bash
docker compose up --build
```

אם רוצים להריץ ברקע:

```bash
docker compose up --build -d
```

כדי לעצור את ה-containers:

```bash
docker compose down
```

האפליקציה אמורה לרוץ בכתובת:

```text
http://localhost:5001
```

## 7. איך לבדוק את /health

אפשר לבדוק שהאפליקציה רצה עם:

```bash
curl http://localhost:5001/health
```

תשובה תקינה:

```json
{
  "status": "ok"
}
```

## 8. איך לשלוח בקשות בסיסיות

פתיחת האפליקציה בדפדפן:

```text
http://localhost:5001
```

הוספת TODO דרך curl:

```bash
curl -X POST -d "title=Learn DevOps" http://localhost:5001/add
```

עדכון TODO לפי מזהה:

```bash
curl http://localhost:5001/update/1
```

מחיקת TODO לפי מזהה:

```bash
curl http://localhost:5001/delete/1
```

## 9. איך להתחבר למסד הנתונים MySQL בזמן שה-containers רצים

קודם מוודאים שה-containers רצים:

```bash
docker compose ps
```

כניסה ל-MySQL container:

```bash
docker exec -it mysql mysql -u flask -p flask
```

לאחר מכן מכניסים את הסיסמה שהוגדרה במשתנה הסביבה `DB_PASSWORD`.

בתוך MySQL אפשר להריץ:

```sql
SHOW TABLES;
SELECT * FROM todo;
```

## 10. Docker Hub image

שם ה-image ב-Docker Hub:

```text
shlomodevops/devops-final-projectshlomo
```

פקודת pull:

```bash
docker pull shlomodevops/devops-final-projectshlomo:latest
```

אפשר גם למשוך image לפי commit SHA אם התג קיים ב-Docker Hub.

## 11. מה עדיין מתוכנן

בהמשך הפרויקט מתוכננים השלבים הבאים:

- Deployment ל-AWS EC2
- שימוש ב-Nginx לפני Flask
- Terraform בסוף, כדי ליצור תשתית בצורה אוטומטית

בשלב הנוכחי אין עדיין AWS, אין Terraform, ואין deployment.
