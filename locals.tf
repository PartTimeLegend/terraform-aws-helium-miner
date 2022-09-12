locals {
  user_data = <<EOF
    #!/bin/bash -xe
    # Enable Swap
    dd if=/dev/zero of=/swapfile bs=128M count=8
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    swapon -s
    echo '/swapfile swap swap defaults 0 0' | tee -a /etc/fstab > /dev/nul
            
    # Get Docker
    yum install docker amazon-cloudwatch-agent -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
            
    # Install the miner
    mkdir /home/ec2-user/miner_data && mkdir /home/ec2-user/miner_logs
    docker run -d --restart always --env REGION_OVERRIDE=EU868 --publish 1680:1680/udp --publish 44158:44158/tcp --name miner --mount type=bind,source=/home/ec2-user/miner_data,target=/var/data --mount type=bind,source=/home/ec2-user/miner_logs,target=/var/log/miner quay.io/team-helium/miner:latest-arm64
            
    # Create backup script and run it
    cat <<EOL > /home/ec2-user/backup_swarm_key.sh 
    #!/bin/bash -x
    while true; do
      aws s3 ls s3://${aws_s3_bucket.bucket.bucket}/swarm_key
      if [ \$? -eq 0 ]; then
        echo "Swarm key found, exiting..."
        break
      fi
      echo "Swarm key not found, copying file..."
      sleep 5
      aws s3 cp /home/ec2-user/miner_data/miner/swarm_key s3://${aws_s3_bucket.bucket.bucket}/swarm_key
    done
    EOL
    chmod +x /home/ec2-user/backup_swarm_key.sh
    /home/ec2-user/backup_swarm_key.sh &> /home/ec2-user/backup_swarm_key.log 2>&1 &
            
    # Create block height metric script and intall the crontab
    cat <<EOL > /home/ec2-user/check_height_delta.sh
    #!/bin/bash -x         
    miner_height=\$(docker exec miner miner info height | awk '{print \$2}')
    miner_name=\$(docker exec miner miner info name)
    network_height=\$(echo \$(echo \$(curl https://api.helium.io/v1/blocks/height) | rev | cut -d":" -f1 | rev) | rev |cut -b 3- | rev)
    miner_height_delta=\$((\$network_height-\$miner_height))
    aws cloudwatch put-metric-data --metric-name BlockHeightDelta --namespace Helium --unit Count --value \$(echo \$miner_height_delta) --dimensions Miner=\$(echo \$miner_name) --region eu-west-1
    EOL
    chmod +x /home/ec2-user/check_height_delta.sh
    crontab<<EOF
    */5 * * * * /home/ec2-user/check_height_delta.sh &> /home/ec2-user/check_height_delta.log 2>&1 &
            
    ## Configure logrotate 
    cat <<EOL > /etc/logrotate.d/helium
    /home/ec2-user/miner_logs/*log {
      daily
      rotate 30
      compress
    }
    EOL
    ## Configure log shipping to AWS CloudWatch Logs
    cat <<EOL > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              { 
                "log_group_name": "HELIUM_MINER",
                "file_path": "/home/ec2-user/miner_logs/error.log",
                "log_stream_name": "{instance_id}/home/ec2-user/miner_logs/error.log"
              },
              { 
                "log_group_name": "HELIUM_MINER",
                "file_path": "/home/ec2-user/miner_logs/console.log",
                "log_stream_name": "{instance_id}/home/ec2-user/miner_logs/console.log"
              },
              { 
                "log_group_name": "HELIUM_MINER",
                "file_path": "/home/ec2-user/miner_logs/crash.log",
                "log_stream_name": "{instance_id}/home/ec2-user/miner_logs/crash.log"
              },
              { 
                "log_group_name": "HELIUM_MINER",
                "file_path": "/home/ec2-user/backup_swarm_key.log",
                "log_stream_name": "{instance_id}/home/ec2-user/backup_swarm_key.log"
              },
              { 
                "log_group_name": "HELIUM_MINER",
                "file_path": "/home/ec2-user/check_height_delta.log",
                "log_stream_name": "{instance_id}/home/ec2-user/check_height_delta.log"
              }
            ]
          }
        }
      }
    }
    EOL
    systemctl start amazon-cloudwatch-agent
    systemctl enable amazon-cloudwatch-agent
  EOF
}
