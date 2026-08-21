"""Belgium copperplate in PyPSA: base and 2x demand, for the capacity-expansion
comparison. One AC bus, no lines -- so no KVL/transport distinction to make."""
import json, sys, time
import pypsa

NET = r"C:\Users\admin\source\pypsa-eur-v2026\results\be-year\networks\base_s_1_elec_.nc"
OUT = sys.argv[1]

def summarise(n, tag, secs):
    wg = n.snapshot_weightings.generators
    gen = n.generators_t.p.mul(wg, axis=0).sum()
    out = {
        "tag": tag, "solve_s": secs,
        "objective": float(n.objective),
        "objective_constant": float(getattr(n, "objective_constant", 0.0) or 0.0),
        "load_total": float(n.loads_t.p_set.mul(wg, axis=0).sum().sum()),
        "generation_total": float(gen.sum()),
        "gen_p_nom_opt": {k: float(v) for k, v in
                          n.generators.p_nom_opt.groupby(n.generators.carrier).sum().items()},
        "gen_p_nom": {k: float(v) for k, v in
                      n.generators.p_nom.groupby(n.generators.carrier).sum().items()},
        "generation_by_carrier": {k: float(v) for k, v in
                                  gen.groupby(n.generators.carrier).sum().items()},
    }
    out["objective_total"] = out["objective"] + out["objective_constant"]
    if len(n.storage_units):
        su = n.storage_units
        out["su_p_nom_opt"] = {k: float(v) for k, v in su.p_nom_opt.groupby(su.carrier).sum().items()}
    if len(n.stores):
        out["store_e_nom_opt"] = {k: float(v) for k, v in
                                  n.stores.e_nom_opt.groupby(n.stores.carrier).sum().items()}
    if len(n.links):
        out["link_p_nom_opt"] = {k: float(v) for k, v in
                                 n.links.p_nom_opt.groupby(n.links.carrier).sum().items()}
    return out

res = {}
for tag, factor in (("base", 1.0), ("x2", 2.0)):
    n = pypsa.Network(NET)
    if factor != 1.0:
        n.loads_t.p_set = n.loads_t.p_set * factor
    print(f"\n--- {tag}: load {n.loads_t.p_set.sum().sum():,.1f} MWh, "
          f"peak {n.loads_t.p_set.sum(axis=1).max():,.1f} MW ---")
    t0 = time.time()
    n.optimize(solver_name="highs")
    secs = time.time() - t0
    res[tag] = summarise(n, tag, secs)
    print(f"{tag}: objective {res[tag]['objective']:,.2f}  "
          f"constant {res[tag]['objective_constant']:,.2f}  "
          f"total {res[tag]['objective_total']:,.2f}  ({secs:.1f} s)")

with open(OUT, "w") as f:
    json.dump(res, f, indent=2)
print("\nwrote", OUT)
