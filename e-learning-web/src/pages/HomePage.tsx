import React from 'react';

const HomePage: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="bg-white dark:bg-gray-800 shadow-lg rounded-xl p-8 max-w-lg w-full text-center">
        <h1 className="text-2xl font-semibold text-gray-900 dark:text-white mb-4">Welcome back</h1>
        <p className="text-gray-600 dark:text-gray-300">
          You are signed in. This is a placeholder home page for non-admin users.
        </p>
      </div>
    </div>
  );
};

export default HomePage;
