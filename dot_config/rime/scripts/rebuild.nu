print "removing old build files..."
rm -rf ./build
print "done"
print "building new config..."
let buildTime = timeit { WeaselDeployer.exe /deploy }
print $"done, took ($buildTime)"
