export function Facturas({ total }: { total: number }) {
  return (
    <section className="p-6">
      <h1 className="text-2xl font-semibold">Facturas del mes</h1>
      <p className="max-w-prose text-slate-600">Total a cobrar: {total}</p>
      <button className="rounded-md bg-slate-900 px-4 py-2 text-white">Ver 12 facturas</button>
    </section>
  );
}
