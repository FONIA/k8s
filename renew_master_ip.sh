#!/bin/bash;
if [ $# != 2 ];then
    echo "k8s更新master的ip，入参：旧ip 新ip"
    exit 0
fi
#原ip
o_ip=$1
#新ip
n_ip=$2
t_stm=`date "+%s"`

#替换/etc/kubernetes中与IP地址关联的配置
find . -type f | xargs sed -i "s/$o_ip/$n_ip/"
if [ $? != 0 ];then
    echo -e '\E[1;31m [x] 替换/etc/kubernetes中的IP失败 \E[0m'
    exit 0
fi

#更新/etc/hosts的ip
sed -i "s/$o_ip/$n_ip/g" /etc/hosts

#重新生成 etcd-server 证书
if [ -f "/etc/kubernetes/pki/etcd/server.crt" ];then
    rm -rf /etc/kubernetes/pki/etcd/server.crt
fi
if [ -f "/etc/kubernetes/pki/etcd/server.key" ];then
    rm -rf /etc/kubernetes/pki/etcd/server.key
fi
kubeadm init phase certs etcd-server
if [ ! -f "/etc/kubernetes/pki/etcd/server.crt" ];then
    echo -e '\E[1;31m [x] /etc/kubernetes/pki/etcd/server.crt生成失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/etcd/server.crt \E[0m'
fi
if [ ! -f "/etc/kubernetes/pki/etcd/server.key" ];then
    echo -e '\E[1;32m [x] /etc/kubernetes/pki/etcd/server.key生成失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/etcd/server.key \E[0m'
fi

#重新生成 apiserver 证书
if [ -f "/etc/kubernetes/pki/apiserver.key" ];then
    rm -rf /etc/kubernetes/pki/apiserver.key
fi
if [ -f "/etc/kubernetes/pki/apiserver.crt" ];then
    rm -rf /etc/kubernetes/pki/apiserver.crt
fi
kubeadm init phase certs apiserver  --apiserver-advertise-address $n_ip
if [ ! -f "/etc/kubernetes/pki/apiserver.key" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/apiserver.key失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/apiserver.key \E[0m'
fi
if [ ! -f "/etc/kubernetes/pki/apiserver.crt" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/apiserver.crt失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/apiserver.crt \E[0m'
fi

#重新生成 apiserver-kubelet-client 证书
if [ -f "/etc/kubernetes/pki/apiserver-kubelet-client.key" ];then
    rm -rf /etc/kubernetes/pki/apiserver-kubelet-client.key
fi
if [ -f "/etc/kubernetes/pki/apiserver-kubelet-client.crt" ];then
    rm -rf /etc/kubernetes/pki/apiserver-kubelet-client.crt
fi
kubeadm init phase certs apiserver-kubelet-client
if [ ! -f "/etc/kubernetes/pki/apiserver-kubelet-client.crt" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/apiserver-kubelet-client.crt失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/apiserver-kubelet-client.crt \E[0m'
fi
if [ ! -f "/etc/kubernetes/pki/apiserver-kubelet-client.key" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/apiserver-kubelet-client.key失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/apiserver-kubelet-client.key \E[0m'
fi

#重新生成 front-proxy-client 证书
if [ -f "/etc/kubernetes/pki/front-proxy-client.crt" ];then
    rm -rf /etc/kubernetes/pki/front-proxy-client.crt
fi
if [ -f "/etc/kubernetes/pki/front-proxy-client.key" ];then
    rm -rf /etc/kubernetes/pki/front-proxy-client.key
fi
kubeadm init phase certs front-proxy-client
if [ ! -f "/etc/kubernetes/pki/front-proxy-client.key" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/front-proxy-client.key失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/front-proxy-client.key \E[0m'
fi
if [ ! -f "/etc/kubernetes/pki/front-proxy-client.crt" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/front-proxy-client.crt失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成/etc/kubernetes/pki/front-proxy-client.crt \E[0m'
fi

#生成新的config文件
if [ -f "/etc/kubernetes/admin.conf" ];then
    rm -rf /etc/kubernetes/admin.conf
fi
kubeadm init phase kubeconfig admin --apiserver-advertise-address $n_ip
if [ ! -f "/etc/kubernetes/admin.conf" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/admin.conf失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成新的/etc/kubernetes/admin.conf文件 \E[0m'
fi

#重启docker\kubelet
systemctl daemon-reload && systemctl restart docker && systemctl restart kubelet
echo -e '\E[1;32m [v] 重启docker、kubelet \E[0m'
#将配置文件config输出
if [ ! -f "/etc/kubernetes/admin.conf" ];then
    echo '\E[1;31m [x] /etc/kubernetes/admin.conf文件不存在 \E[0m'
    exit 0
fi
kubectl get nodes --kubeconfig=/etc/kubernetes/admin.conf
#将kubeconfig默认配置文件替换为admin.conf，这样就可以直接使用kubectl get nodes
mv /etc/kubernetes/admin.conf ~/.kube/config

if [ $? == 0 ];then
    echo -e '\E[1;32m success \E[0m'
    exit 0
fi

echo -e '\E[1;31m fail \E[0m'

