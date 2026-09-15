import { useEffect, useState } from 'react'

function App() {
  const [message, setMessage] = useState('Loading...')

  useEffect(() => {
    fetch('http://localhost:8080/api/hello')
      .then((res) => res.text())
      .then(setMessage)
      .catch(() => setMessage('Failed to reach backend'))
  }, [])

  return (
    <div>
      <h1>Launchpad</h1>
      <p>Backend says: {message}</p>
    </div>
  )
}

export default App
