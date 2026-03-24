import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Login from './pages/Login';
import Signup from './pages/Signup';
import Home from './pages/Home';
import ProblemEditor from './pages/ProblemEditor';
import BattleLobby from './pages/BattleLobby';
import BattleArena from './pages/BattleArena';
import Rankings from './pages/Rankings';
import Profile from './pages/Profile';
import Discuss from './pages/Discuss';
import { Roadmaps, Chats, Vault, Settings } from './pages/Stubs';
import { DashboardLayout } from './components/DashboardLayout';

// Route Guard for Protected Routes
const PrivateRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { currentUser, loading } = useAuth();

  if (loading) return <div style={{ padding: 20 }}>Checking session context...</div>;

  return currentUser ? <>{children}</> : <Navigate to="/login" />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route 
            path="/" 
            element={
              <PrivateRoute>
                <DashboardLayout />
              </PrivateRoute>
            } 
          >
            <Route index element={<Home />} />
            <Route path="battle" element={<BattleLobby />} />
            <Route path="rankings" element={<Rankings />} />
            <Route path="profile" element={<Profile />} />
            <Route path="discuss" element={<Discuss />} />
            <Route path="roadmaps" element={<Roadmaps />} />
            <Route path="chats" element={<Chats />} />
            <Route path="vault" element={<Vault />} />
            <Route path="settings" element={<Settings />} />
          </Route>
          {/* Full Screen Pages (Outside Sidebar shell) */}
          <Route 
            path="/problem/:company/:id" 
            element={
              <PrivateRoute>
                <ProblemEditor />
              </PrivateRoute>
            } 
          />
          <Route 
            path="/battle/arena/:id" 
            element={
              <PrivateRoute>
                <BattleArena />
              </PrivateRoute>
            } 
          />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
