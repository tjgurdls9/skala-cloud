const express = require("express");
const mysql = require("mysql2");
const os = require("os");

const app = express();
const db = mysql.createPool({
  host: process.env.DB_HOST || "mariadb-3tier",
  user: "user",
  password: "password123",
  database: "skala",
});

app.get("/users", (req, res) => {
  db.query("SELECT id, username, email FROM users", (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ container: os.hostname(), users: rows });
  });
});

app.get("/whoami", (req, res) => res.json({ container: os.hostname() }));

app.listen(8080, () => console.log("WAS " + os.hostname()));
