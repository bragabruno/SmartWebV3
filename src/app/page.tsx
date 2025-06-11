import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold text-center">
        SmartWebV3
      </h1>
      <p className="mt-4 text-xl text-center">
        Lead Generation & Sales Automation Platform
      </p>
      <Link
        href="/auth/signin"
        className="mt-8 inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        Get Started
      </Link>
    </main>
  );
}