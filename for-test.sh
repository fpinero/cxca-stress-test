for ((i=1; i<=600; i++))
do
  ./test-back-cxca.sh -e cloudflare
  sleep 1
done
