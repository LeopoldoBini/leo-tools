export function Hero() {
  return (
    <section className="relative bg-gradient-to-br from-violet-600 to-fuchsia-500">
      <div className="absolute blur-3xl bg-purple-500/30" />
      <span className="text-xs uppercase tracking-widest text-white/60">01 — Features</span>
      <h1 className="font-serif italic tracking-tight">Build <em>faster</em>. Ship <em>smarter</em>.</h1>
      <p className="text-center text-white/70">The <em>only</em> platform you need.</p>
      <span className="rounded-full px-2 bg-white/10">New</span>
      <span className="rounded-full px-2 bg-white/20">Beta</span>
      <span className="rounded-full px-3 bg-white/5">AI</span>
      <div className="border shadow-lg rounded-xl bg-white/15 text-white/80 border-white/40">🚀 Fast</div>
    </section>
  );
}
