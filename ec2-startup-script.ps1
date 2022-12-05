$InstanceId = 'YOUR_INSTANCE_ID'
$AWSCliProfile = 'remote-dev-admin'
$BootSleepDuration = 16
$SleepDuration = 8
$MaxSleepIterations = 10
$ElapsedTime = 0

function Write-InstanceStatus { 
    [CmdletBinding()]
	param(
		[Parameter()]
		[string] $InstanceState
	)
    Write-Host 'EC2 instance current state: '$InstanceState'.  Waiting for instance to come online.. ('$ElapsedTime's elapsed)'
}

Write-Host 'Attempting to start EC2 instance...'
$startInstanceResponse = aws ec2 start-instances --profile $AWSCliProfile --instance-ids $InstanceId --output text --query 'StartingInstances[0].CurrentState.Name'
Write-InstanceStatus -InstanceState $startInstanceResponse

$Count=0
do {
    $InstanceStatus = aws ssm describe-instance-information --profile $AWSCliProfile --filters Key=InstanceIds,Values=$InstanceId --output text --query 'InstanceInformationList[0].PingStatus'
    if ($InstanceStatus -ne 'Online') {
        $InstanceStatus = 'pending'
    }
    if ($InstanceStatus -eq 'Online') {        
        Write-Host 'Instance now online, starting RDP via web interface...'
        Start-Sleep -s 3
        
        #launch RDP via web interface
        $InstanceIpAddress = aws ec2 describe-instances --profile $AWSCliProfile --instance-ids $InstanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
        $InstanceUrl = 'https://'+$InstanceIpAddress+'#'+$InstanceId
        Start-Process $InstanceUrl              

        $quit = Read-Host "Enter q to quit and shutdown AWS EC2 instance"
        if ($quit -eq 'q') {
            #stop instance
            Write-Host "Stopping AWS EC2 instance..."
            aws ec2 stop-instances --profile $AWSCliProfile --instance-ids $InstanceId --query 'StoppingInstances[0].CurrentState.Name'
            Write-Host "Exiting program"
            Start-Sleep -s $SleepDuration
        break
        }
    }

    if ($Count -eq $MaxSleepIterations) {
        Write-Host 'Max sleep iteration reached.  Exiting program'
        Start-Sleep -s $SleepDuration
        exit 1
    }
    else {
        Start-Sleep -s $BootSleepDuration
        $ElapsedTime = $ElapsedTime + $BootSleepDuration
        $Count++
    }
    Write-InstanceStatus -InstanceState $InstanceStatus
} while ($Count -le $MaxSleepIterations)