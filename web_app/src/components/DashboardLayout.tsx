import React from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { 
  BarChart2, Map, MessageSquare, Flame, 
  MessageCircle, User, Award, Shield, Settings 
} from 'lucide-react';

const Sidebar: React.FC = () => {
  const navItems = [
    { icon: <BarChart2 size={24} />, label: 'Dashboard', path: '/' },
    { icon: <Map size={24} />, label: 'Roadmaps', path: '/roadmaps' },
    { icon: <MessageSquare size={24} />, label: 'Chats', path: '/chats' },
    { icon: <Flame size={24} />, label: 'Battle', path: '/battle' },
    { icon: <MessageCircle size={24} />, label: 'Discuss', path: '/discuss' },
    { icon: <User size={24} />, label: 'Profile', path: '/profile' },
    { icon: <Award size={24} />, label: 'Rankings', path: '/rankings' },
    { icon: <Shield size={24} />, label: 'Vault', path: '/vault' },
    { icon: <Settings size={24} />, label: 'Settings', path: '/settings' },
  ];

  return (
    <div style={{
      width: '80px',
      height: '100vh',
      backgroundColor: 'var(--sidebar-background)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      paddingTop: '32px',
      boxSizing: 'border-box',
    }}>
      {/* Logo */}
      <div style={{
        width: '45px',
        height: '45px',
        background: 'linear-gradient(135deg, var(--accent-blue), #0055FF)',
        borderRadius: '12px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: '32px',
        fontWeight: 'bold',
        fontSize: '24px',
        color: 'white',
      }}>
        C
      </div>

      {/* Nav Items */}
      <div style={{ flex: 1, overflowY: 'auto', width: '100%' }}>
        {navItems.map((item, index) => (
          <NavLink 
            key={index}
            to={item.path}
            style={({ isActive }) => ({
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              padding: '12px 0',
              textDecoration: 'none',
              color: isActive ? 'var(--accent-blue)' : 'var(--text-secondary)',
              borderLeft: isActive ? '3px solid var(--accent-blue)' : 'none',
              transition: 'all 0.2s',
              marginBottom: '4px',
            })}
          >
            {item.icon}
            <span style={{ fontSize: '10px', marginTop: '4px', textAlign: 'center' }}>
              {item.label}
            </span>
          </NavLink>
        ))}
      </div>
    </div>
  );
};

export const DashboardLayout: React.FC = () => {
  return (
    <div style={{ display: 'flex', height: '100vh', width: '100vw' }}>
      <Sidebar />
      <div style={{
        flex: 1,
        background: 'linear-gradient(135deg, var(--background), #0D141C)',
        overflowY: 'auto',
      }}>
        <Outlet />
      </div>
    </div>
  );
};
