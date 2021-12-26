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

if [ ! -f "/etc/kubernetes/manifests/etcd.yaml" ];then
    echo '\E[1;32m [v] /etc/kubernetes/manifests/etcd.yaml文件不存在 \E[0m'
    exit 0
fi
if [ ! -f "/etc/kubernetes/manifests/kube-apiserver.yaml" ];then
    echo '\E[1;31m [x] /etc/kubernetes/manifests/kube-apiserver.yaml文件不存在 \E[0m'
    exit 0
fi
sed -i "s/$o_ip/$n_ip/g" /etc/kubernetes/manifests/etcd.yaml
sed -i "s/$o_ip/$n_ip/g" /etc/kubernetes/manifests/kube-apiserver.yaml
if [ $? == 0 ];then
    echo -e '\E[1;32m [v] etcd.yaml、kube-apiserver.yaml替换ip成功 \E[0m'
else
    echo -e '\E[1;31m [x] etcd.yaml、kube-apiserver.yaml替换ip失败 \E[0m'
    exit 0
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
#删除老证书，生成新证书
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
    echo -e '\E[1;32m [v] 生成新的/etc/kubernetes/pki/apiserver.key文件 \E[0m'
fi
if [ ! -f "/etc/kubernetes/pki/apiserver.crt" ];then
    echo -e '\E[1;31m [x] 生成/etc/kubernetes/pki/apiserver.crt失败 \E[0m'
    exit 0
else
    echo -e '\E[1;32m [v] 生成新的/etc/kubernetes/pki/apiserver.crt文件 \E[0m'
fi
#重启docker
service docker restart
service kubelet restart

#将配置文件config输出
if [ ! -f "/etc/kubernetes/admin.conf" ];then
    echo '\E[1;31m [x] /etc/kubernetes/admin.conf文件不存在 \E[0m'
    exit 0
fi
kubectl get nodes --kubeconfig=/etc/kubernetes/admin.conf
#将kubeconfig默认配置文件替换为admin.conf，这样就可以直接使用kubectl get nodes
mv /etc/kubernetes/admin.conf ~/.kube/config

if [ $? == 0 ];then
    echo -e '\E[1;31m success \E[0m'
    exit 0
fi

echo -e '\E[1;31m fail \E[0m'

