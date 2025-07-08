import React from 'react'
import { Routes, Route } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'

// Pages
import HomePage from './pages/HomePage'
import AboutPage from './pages/AboutPage'
import ProjectsPage from './pages/ProjectsPage'
import ContactPage from './pages/ContactPage'

// Components
import Navbar from './components/Navbar'
import Footer from './components/Footer'

const App: React.FC = () => {
  return (
    <>
      <Helmet>
        <title>ITSANDBOX - 法政大学 IT Innovation Community</title>
        <meta name="description" content="法政大学の仲間と一緒に、わくわくするプロジェクトを開発するコミュニティです！" />
      </Helmet>
      
      <div className="min-h-screen bg-gradient-bg selection-primary">
        <Navbar />
        
        <main className="pt-16">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/about" element={<AboutPage />} />
            <Route path="/projects" element={<ProjectsPage />} />
            <Route path="/contact" element={<ContactPage />} />
          </Routes>
        </main>
        
        <Footer />
      </div>
    </>
  )
}

export default App