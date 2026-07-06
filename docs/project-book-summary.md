# תקציר והכנה להגנה

## 1. תקציר הפרויקט

הפרויקט הוא מערכת Web להזמנת מקומות למשחקי World Cup 2026. האפליקציה כתובה ב־Flask, משתמשת ב־SQLAlchemy ומחוברת ל־MySQL. המשתמש יכול לצפות במשחקים, להזמין מקומות, לנהל הזמנה קיימת ולבטל הזמנה. בנוסף קיימת עמדת admin לצפייה בהזמנות ובסטטיסטיקות.

מבחינת DevOps, המערכת נארזת ב־Docker, מורצת עם Docker Compose, נחשפת דרך Nginx, רצה עם Gunicorn, ונפרסת ל־AWS EC2 באמצעות GitHub Actions. ה־pipeline מריץ בדיקות, בונה Docker image, מפרסם אותו ל־Docker Hub, מתחבר ל־EC2, מעדכן `IMAGE_TAG`, מפעיל Docker Compose ובודק `/health`. אם ה־deployment נכשל, ה־workflow מבצע rollback לתג הקודם.

Terraform קיים בפרויקט ומשמש ליצירת תשתית AWS: EC2, Security Group, Elastic IP, Key Pair במידת הצורך ו־bootstrap עם Docker/Git. Terraform state נשמר ב־S3 תחת `prod/terraform.tfstate`, כדי לאפשר עבודה עם GitHub Actions runners זמניים.

המערכת כוללת ניטור בסיסי: `/health` לבדיקת זמינות, `/metrics` ל־Prometheus, ו־Grafana להצגת metrics. לא נמצא בפרויקט REST API אפליקטיבי, Kubernetes, Jenkins, Load Balancer, HTTPS, Domain או RDS.

## 2. שאלות ותשובות להגנה

### שאלה 1: מה מטרת הפרויקט?

להציג מערכת Web עובדת להזמנת מקומות, יחד עם תהליך DevOps מלא: Docker, Compose, CI/CD, Docker Hub, EC2, Terraform וניטור.

### שאלה 2: האם יש בפרויקט REST API?

לא. לא נמצאו endpoints אפליקטיביים מסוג `/api/...`. המערכת מבוססת Flask routes שמחזירים HTML, ובנוסף קיימים endpoints טכניים: `/health` ו־`/metrics`.

### שאלה 3: מה ההבדל בין Terraform לבין GitHub Actions בפרויקט?

Terraform יוצר תשתית AWS כמו EC2, Security Group ו־Elastic IP. GitHub Actions מבצע deployment של האפליקציה: בדיקות, build, push ל־Docker Hub והרצה מחדש ב־EC2.

### שאלה 4: למה צריך S3 remote state ב־Terraform?

כי GitHub Actions runners הם זמניים. אם state היה נשמר מקומית, Terraform לא היה יודע אילו משאבים כבר נוצרו. S3 שומר את state באופן קבוע תחת `prod/terraform.tfstate`.

### שאלה 5: מה Docker Compose עושה כאן?

Docker Compose מריץ כמה containers יחד לפי קובץ YAML אחד. ב־production קיימים services בשם `nginx`, `app`, `mysql`, `prometheus`, ו־`grafana`. זה לא Kubernetes.

### שאלה 6: מה תפקיד Nginx?

Nginx מקבל בקשות HTTP בפורט `80` ומשמש Reverse Proxy אל Flask/Gunicorn דרך `app:5000`.

### שאלה 7: איך מתבצע rollback?

ה־CI/CD שומר את `PREVIOUS_IMAGE_TAG`. אם אחרי deployment הבדיקה `curl http://localhost/health` נכשלת, ה־workflow מחזיר את `IMAGE_TAG` הקודם ומריץ שוב Docker Compose.

### שאלה 8: מה Prometheus ו־Grafana עושים?

Prometheus מושך metrics מ־`app:5000/metrics` כל 15 שניות. Grafana מוגדר לקרוא מ־Prometheus ולהציג נתונים בצורה ויזואלית.

### שאלה 9: איך נשמרים secrets?

קבצי `.env` מוחרגים ב־`.gitignore`. GitHub Actions משתמש ב־GitHub Secrets כמו `DOCKERHUB_TOKEN`, `EC2_SSH_KEY`, ו־AWS credentials. בקוד אין hardcoding של secrets אמיתיים לפי הקבצים שנבדקו.

### שאלה 10: אילו רכיבים לא קיימים בפרויקט?

לא נמצאו בקבצי הפרויקט Kubernetes, Jenkins, Load Balancer, HTTPS, Domain, REST API אפליקטיבי, RDS או external secrets manager.

