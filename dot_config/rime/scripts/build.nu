print "building new config..."
let buildTime = timeit { WeaselDeployer.exe /deploy }
print $"done, took ($buildTime)"
