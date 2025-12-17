import os
from flask import Flask, render_template, redirect, url_for, request, session
from flask_dance.contrib.google import make_google_blueprint, google
os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

app = Flask(__name__)
app.secret_key = "SUPER_SECRET_KEY_12345"

google_bp = make_google_blueprint(
    client_id="433878843600-9nqdf0p5tbndi2qlrg55c1252m70tcvi.apps.googleusercontent.com",
    client_secret="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",
    scope=[
        "openid",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile"
    ],

    reprompt_consent=True, 
    redirect_to="google_login"
)
app.register_blueprint(google_bp, url_prefix="/login")

@app.route("/", methods=["GET", "POST"])
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("Username")
        password = request.form.get("Password")


        if username == "admin" and password == "123":
            session.clear()
            session["login_type"] = "normal"
            session["user"] = username
            return redirect(url_for("dashboard"))
        

        return f"""
        <h2>Invalid Username or Password</h2>
        <p>Please try again or use Google sign-in.</p>
        <a href="{url_for('logout')}">Log out</a> 
        """

    return render_template("login.html")


@app.route("/google_login")
def google_login():

    if not google.authorized:
        return redirect(url_for("google.login"))


    resp = google.get("/oauth2/v2/userinfo")
    
    if not resp.ok:

        return "Failed to get Google user data"

    info = resp.json()

    session.clear()
    session["login_type"] = "google"
    session["google_user"] = {
        "name": info.get("name"),
        "email": info.get("email"),
        "picture": info.get("picture")
    }

    return redirect(url_for("dashboard"))

@app.route("/dashboard")
def dashboard():
    if "login_type" not in session:
        return redirect(url_for("login"))

    if session["login_type"] == "google":
        user = session["google_user"]
        return f"""
        <h2>Google Profile</h2>
        <img src="{user['picture']}" width="120" style="border-radius:50%"><br><br>
        <b>Name:</b> {user['name']}<br>
        <b>Email:</b> {user['email']}<br><br>
        <a href="/logout">Logout</a>
        """

    if session["login_type"] == "normal":
        return f"""
        <h2>Welcome {session['user']}</h2>
        <a href="/logout">Logout</a>
        """
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)
