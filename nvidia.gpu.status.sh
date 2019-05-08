#!/bin/bash
# Author: 运维Time
# Date  : 2017-11-10

gpu=$1
item=$2

if [[ ! -f "/tmp/jq.flag" ]]; then
    if [[ -n "`rpm -qa jq`" ]]; then
        touch /tmp/jq.flag
    else
        yum -q -y install jq 2>/dev/null
        if [ $? -eq 0 ]; then
            touch /tmp/jq.flag
        fi
    fi
fi

gpuinfo=`
nvidia-smi  -q |awk '{
if($0~/^GPU/) n=p++;
if($0~/FB Memory Usage/){
    getline;gpu[n]["fb_total"]=$3;
    getline;gpu[n]["fb_used"]=$3;
    getline;gpu[n]["fb_free"]=$3};
if($0~/BAR1 Memory Usage/){
    getline;gpu[n]["bar1_total"]=$3;
    getline;gpu[n]["bar1_used"]=$3;
    getline;gpu[n]["bar1_free"]=$3};
if($0~/Utilization/){
    getline;gpu[n]["util_gpu"]=$3;
    getline;gpu[n]["util_memory"]=$3;
    getline;gpu[n]["util_encoder"]=$3;
    getline;gpu[n]["util_decoder"]=$3};
if($0~/Processes/){
    while(getline){if($0~/Process ID/){PNUM++}};
    gpu[n]["pnum"]=PNUM}
}
END{
    print "{";
    li=length(gpu);
    for(i in gpu){ 
        gpu[i]["util_gpu_memory"]=(gpu[i]["fb_used"]/gpu[i]["fb_total"])*100;
        gpu[i]["util_bar1_memory"]=(gpu[i]["bar1_used"]/gpu[i]["bar1_total"])*100;

        k++;
        kk=0;
        print "\""i"\"",":";
        print "{";
        lj=length(gpu[i]);
        for(j in gpu[i]){
            kk++;
            if(lj==kk){
                print "\""j"\":",gpu[i][j];
            }else{
                print "\""j"\":",gpu[i][j],",";
            };
        };
        print "}";
        if(li!=k){
            print ",";
        }
    };
    print "}";
}
'`

if [[ $gpu == "disc" ]]; then
    len=`echo $gpuinfo | jq '.|length'`
    ((len--))
    ret=$(
    echo "{\"data\":[";
    for i in `seq 0 $len`; do
        echo "{";
        echo "\"{#GPU}\":\"$i"\";
        if [ $len -eq $i ]; then
            echo "}";
        else
            echo "},";
        fi;
    done;
    echo "]}";)
    echo $ret | jq '.'
else
    echo $gpuinfo | jq '."'$gpu'"."'$item'"';
fi
