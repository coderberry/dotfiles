# Kill a port based on the port number
kill-port() {
  PID=$(lsof -ti ":1")
  if [ ! -z "$PID" ]; then
    echo "PORT: $1"
    echo "PID:  $PID"
    kill -9 $PID
    echo "OK!"
  else
    echo "No Process Found running Port $1"
  fi
}
