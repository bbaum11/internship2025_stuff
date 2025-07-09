from flask import Flask, request, render_template, redirect, url_for
from werkzeug.middleware.proxy_fix import ProxyFix
import psycopg2
import os

app = Flask(__name__)

conn = psycopg2.connect(
  dbname=os.environ.get("DB_NAME"),
  user=os.environ.get("DB_USER"),
  password=os.environ.get("DB_PASSWORD"),
  host=os.environ.get("DB_HOST"),
)
cur = conn.cursor()

cur.execute(
  '''CREATE TABLE IF NOT EXISTS products (id serial \
    PRIMARY KEY, name varchar(100), price float);'''
)

curr.execute(
  "select count(*) FROM products;"
)
count = cur.fetchone()[0]
if count == 0:
  cur.execute(
    '''INSERT INTO products (name, price) VALUES \
    ('Apple', 1.99), ('Orange', 0.99), ('Banana', 0.59);'''
  )
conn.commit()
cur.close()
conn.close()

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

@app.route('/')
def index():
  conn = psycopg2.connect(
    dbname=os.environ.get("DB_NAME"),
    user=os.environ.get("DB_USER"),
    password=os.environ.get("DB_PASSWORD"),
    host=os.environ.get("DB_HOST"),
  )
  cur = conn.cursor(
  cur.execute('''SELECT * FROM products''')
  data = cur.fetchall()
  cur.close()
  conn.close()
  return render_template('index.html', data=data)

@app.route('/create', methods=['POST'])
def create():
  conn = psycopg2.connect(
    dbname=os.environ.get("DB_NAME"),
    user=os.environ.get("DB_USER"),
    password=os.environ.get("DB_PASSWORD"),
    host=os.environ.get("DB_HOST"),
  )
  cur = conn.cursor()
  name = request.form['name']
  price = request.form['price']
  cur.execute(
      '''INSERT INTO products \
      (name, price) VALUES (%s, %s)''',
      (name, price)
  )
  conn.commit()
  cur.close()
  conn.close()
  return redirect(url_for('index'))

@app.route('/update', methods=['POST'])
def update():
  conn = psycopg2.connect(
    dbname=os.environ.get("DB_NAME"),
    user=os.environ.get("DB_USER"),
    password=os.environ.get("DB_PASSWORD"),
    host=os.environ.get("DB_HOST"),
  )
  cur = conn.cursor()
  name = request.form['name']
  price = request.form['price']
  id = request.form['id']
  cur.execute(
      '''UPDATE products SET name=%s,\
      price=%s WHERE id=%s''', (name, price, id))
  conn.commit()
  return redirect(url_for('index'))

@app.route('/delete', methods=['POST'])
def delete():
  conn = psycopg2.connect(
    dbname=os.environ.get("DB_NAME"),
    user=os.environ.get("DB_USER"),
    password=os.environ.get("DB_PASSWORD"),
    host=os.environ.get("DB_HOST"),
  )
  cur = conn.cursor()
  id = request.form['id']
  cur.execute('''DELETE FROM products WHERE id=%s''', (id,))
  conn.commit()
  cur.close()
  conn.close()
  return redirect(url_for('index'))


if __name__ == '__main__':
  app.run(debug=True)
