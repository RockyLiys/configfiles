echo "创建一个临时文件夹"
SERVER_INIT_TMP_PATH=/tmp/serverinit
mkdir -p $SERVER_INIT_TMP_PATH && cd $SERVER_INIT_TMP_PATH

sudo yum install lrzsz

echo "安装 Python 依赖 和 pip"
sudo yum install python-devel -y
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py

sudo pip install -U virtualenvwrapper

# setup virtualenv
echo '''
# virtualenv
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/workspace
source /usr/bin/virtualenvwrapper.sh
#source /usr/local/bin/virtualenvwrapper.sh
''' >> ~/.bashrc

echo "初始化 virtualenv，使环境变量立即生效"
source ~/.bashrc

# 下载编译 tengine(nginx) 
echo "安装 tengine(nginx) 依赖"
sudo yum install pcre-devel openssl-devel -y

echo "创建 tengine-src 文件夹...";
mkdir tengine-src
cd tengine-src

echo "下载 tengine 源代码...";
wget http://tengine.taobao.org/download/tengine-2.2.0.tar.gz

echo "解压下载文件...";
tar -xvzf tengine-2.2.0.tar.gz

echo "编译tengine...";
cd tengine-2.2.0
./configure
make -j2

echo "tengine(nginx) 编译完成，安装";
sudo make install

echo "启动tengine(nginx)，配置文件在 /usr/local/nginx/conf 中";
sudo /usr/local/nginx/sbin/nginx -s start

cd $SERVER_INIT_TMP_PATH
echo "安装 supervisor 和 uwsgi"
sudo pip install supervisor uwsgi
echo_supervisord_conf > ./supervisord.conf
sudo cp ./supervisord.conf /etc/

echo "安装MySQL相关"
echo '''# Enable to use MySQL 5.6
# /etc/yum.repos.d/
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/7/$basearch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
''' > ./mysql56.repo
sudo cp ./mysql56.repo /etc/yum.repos.d/

sudo yum makecache
sudo yum install mysql-community-devel -y

echo "可选安装 MySQL-server"
sudo yum install mysql-community-server -y

echo "部署 django 项目"
PROJECT_NAME=flinfo
PROJECT_PATH=~/$PROJECT_NAME

mkvirtualenv $PROJECT_NAME
workon $PROJECT_NAME

cd $PROJECT_PATH
pip install -U pip
pip install -r requirements.txt