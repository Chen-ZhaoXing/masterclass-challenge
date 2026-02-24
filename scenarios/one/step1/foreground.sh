echo "Installing scenario..."
while [ ! -f /opt/background-finished ]; do sleep 1; done
echo DONE

helm upgrade --install challenge1 ~/masterclass-fastapi-app -n challenge1

kubectl wait --for=condition=available deployment challenge1 -n challenge1 --timeout=60s || true

cd ~/masterclass-fastapi-app
