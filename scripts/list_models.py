import httpx

key = ""
for line in open(".env", encoding="utf-8"):
    if line.startswith("GROQ_API_KEY"):
        key = line.split("=", 1)[1].strip()

r = httpx.get(
    "https://api.groq.com/openai/v1/models",
    headers={"Authorization": "Bearer " + key},
    timeout=30,
)

if r.status_code != 200:
    print(r.status_code, r.text[:400])
else:
    for m in sorted(x["id"] for x in r.json()["data"]):
        print(m)
