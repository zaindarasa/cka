#!/usr/bin/env python3
"""Regenerate guide/VERIFY-LIST.md from each lesson's '## 11. To verify' section.

Keeps the section body verbatim except:
- drops '- [x]' / '- [ ]' checkbox lines (done-criteria self-checks)
- drops 'Done criteria' intro bullets and bare '---' rules
- rewrites '](../partN-*' links to '](partN-*' so they resolve from guide/ root
Usage: python3 guide/tools/gen-verify.py
"""
import re, pathlib
G = pathlib.Path(__file__).resolve().parent.parent
vms = {'T4.01','T4.02','T4.03','T4.04','T4.05','T4.17','T4.18','T4.23','T4.25','T4.26','T4.27'}
mixed = {'T4.10','T4.13','T4.16'}

def clean(body):
    out = []
    for l in body.splitlines():
        if re.match(r'^\s*- \[[ x]\]', l):            continue
        if re.match(r'^\s*[-*]?\s*\**\s*Done criteria', l): continue
        if l.strip() == '---':                       continue
        out.append(l.replace('](../', ']('))
    while out and not out[0].strip(): out.pop(0)
    while out and not out[-1].strip(): out.pop()
    return out

groups = {'linux-vm': [], 'kind': [], 'vms': []}
for d in ['part1-linux','part2-basics','part3-ckad','part4-cka']:
    for f in sorted(G.joinpath(d).glob('T*.md')):
        tid = f.name.split('-')[0]
        text = f.read_text()
        m = re.search(r'^## 11\. To verify\n(.*?)(?=^## |\Z)', text, re.M|re.S)
        if not m: continue
        items = clean(m.group(1))
        if not any(l.strip() for l in items): continue
        env = 'linux-vm' if d=='part1-linux' else ('vms' if tid in vms or tid in mixed else 'kind')
        # Count only labels at the start of a line (optional whitespace and an
        # optional '# ' comment prefix, as inside ```text blocks). Mid-line
        # prose references and '- [ ]' self-check items mentioning the label
        # must not count, so do not use a bare substring findall here.
        n_exp = len(re.findall(r'^\s*(?:#\s*)?EXPECTED OUTPUT \(not captured\)', text, re.M))
        groups[env].append((tid, f.name, n_exp, items))

count = sum(len(i[3]) for g in groups.values() for i in g)
out = ["# VERIFY-LIST", "",
"Everything still to confirm on a live environment, collected verbatim from each lesson's section 11 and grouped by the environment needed. Done-criteria checkbox lines are omitted.",
"",
"- **linux-vm**: one Ubuntu LTS VM (24.04+, 2 vCPU / 4 GB) with systemd and cgroup v2 (`multipass launch --name lab --cpus 2 --memory 4G`).",
"- **kind**: `env/kind-up.sh` (kind v0.33.0, `kindest/node:v1.37.0`, 1 CP + 2 workers, Calico).",
"- **vms**: three Ubuntu LTS VMs prepared with `env/vm-prereqs.sh` (kubeadm 1.37.x, containerd 2.x).",
""]
names = {'linux-vm':'Linux VM items','kind':'kind cluster items','vms':'kubeadm VM items'}
for env in ['linux-vm','kind','vms']:
    out += [f"## {names[env]}", ""]
    for tid, fname, n_exp, items in groups[env]:
        out.append(f"### {tid} ({fname}) — {n_exp} expected-output blocks")
        out += items + [""]
(G/'VERIFY-LIST.md').write_text("\n".join(out))
print(f"wrote VERIFY-LIST.md: {count} content lines across {sum(len(v) for v in groups.values())} lessons")
