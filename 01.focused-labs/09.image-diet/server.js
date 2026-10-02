const express = require("express");
const app = express();

app.get("/", (req, res) => res.send("image-diet demo"));
app.get("/healthz", (req, res) => res.json({ status: "ok" }));

app.listen(3000, () => console.log("listening on 3000"));
