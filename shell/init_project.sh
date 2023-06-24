project_name=project1
app_name=app1

curl -o .gitignore https://github.com/github/gitignore/raw/50e42aa1064d004a5c99eaa72a2d8054a0d8de55/Python.gitignore

cat>.gitattributes<<EOF
# Auto detect text files and perform LF normalization
* text=auto

EOF


cat>README.md<<EOF
# ${project_name}
 project_description

EOF


cat>Dockerfile<<EOF
# 如需更多资料，请参阅 https://aka.ms/vscode-docker-python
FROM python:3.10-slim

EXPOSE 8000

# 防止Python在容器中生成.pyc文件
ENV PYTHONDONTWRITEBYTECODE=1

# 关闭缓冲以便更容易地记录容器日志
ENV PYTHONUNBUFFERED=1

# 安装 pip requirements
COPY requirements.txt .
RUN python -m pip install -r requirements.txt

WORKDIR /app
COPY . /app

# 创建具有显式 UID 的非root用户并添加访问 /app 文件夹的权限
# 如需更多资料，请参阅 https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# 在调试期间，这个入口点将被覆盖。 如需更多资料，请参阅 https://aka.ms/vscode-docker-python-debug
# CMD ["python", "app.py"]
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "${project_name}.wsgi"]

EOF


cat>docker-compose.yml<<EOF
version: '3.4'

services:
  ${project_name}:
    image: ${project_name}
    build:
      context: .
      dockerfile: ./Dockerfile
    ports:
      - 8000:8000
EOF


cat>docker-compose.debug.yml<<EOF
version: '3.4'

services:
  ${project_name}:
    image: ${project_name}
    build:
      context: .
      dockerfile: ./Dockerfile
    command: ["sh", "-c", "pip install debugpy -t /tmp && python /tmp/debugpy --wait-for-client --listen 0.0.0.0:5678 manage.py runserver 0.0.0.0:8000 --nothreading --noreload"]
    ports:
      - 8000:8000
      - 5678:5678

EOF


cat>.dockerignore<<EOF
**/__pycache__
**/.venv
**/.classpath
**/.dockerignore
**/.env
**/.git
**/.gitignore
**/.project
**/.settings
**/.toolstarget
**/.vs
**/.vscode
**/*.*proj.user
**/*.dbmdl
**/*.jfm
**/bin
**/charts
**/docker-compose*
**/compose*
**/Dockerfile*
**/node_modules
**/npm-debug.log
**/obj
**/secrets.dev.yaml
**/values.dev.yaml
LICENSE
README.md

EOF


cat>requirements.txt<<EOF
# 为了确保应用依赖从你的虚拟环境/主机移植到你的容器中，在终端中运行'pip freeze > requirements.txt'来覆盖这个文件
django==4.1.5
gunicorn==20.1.0

EOF