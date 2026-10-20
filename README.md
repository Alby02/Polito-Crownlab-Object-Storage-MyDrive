# CrownLabs · S3-backed My Drive

**Personal storage for cloud VMs: logical disks vs. S3-based volumes**

Research and proof of concept for the **Cloud Computing Technologies** course at **Politecnico di Torino**.

> Can an S3-backed filesystem provide persistent, portable storage for CrownLabs virtual machines?

[Overview](#overview) · [Objectives](#objectives) · [Deliverables](#deliverables) · [Team](#team) · [License](#license)

## Overview

CrownLabs provides immutable virtual machines to students. Data written directly to a VM's local disk may be permanently lost when that VM is deleted and recreated. To support persistence and collaboration, CrownLabs offers two storage facilities mounted inside the VM:

| Facility | Purpose | Managed by |
| --- | --- | --- |
| **My Drive** | Persistent personal storage accessible across a student's VMs | The student |
| **Shared Drive** | Storage shared by all members of a workspace | Workspace administrators, such as professors |

The project brief describes the current implementation as relying on Kubernetes logical volumes. It identifies two limitations:

- **Portability across namespaces:** accessing a volume from another Kubernetes namespace can be cumbersome.
- **Remote-cluster access:** the current approach does not support access to the same volume when computation moves to a remote cluster through Liqo.

This project explores an alternative: attaching **My Drive** to a VM through a filesystem backed by **S3-compatible object storage**. DittoFS is mentioned in the brief as a candidate to investigate; the final software selection will be discussed with the tutor.

## Objectives

1. **Explore the ecosystem** — identify filesystem-to-S3 software.
2. **Evaluate suitable solutions** — compare candidates and present the proposed selection to the tutor.
3. **Build a proof of concept** — demonstrate a working My Drive setup using the selected software.
4. **Measure performance** — run preliminary benchmarks against the current My Drive implementation.

## Deliverables

| Deliverable | Expected outcome |
| --- | --- |
| **Software survey** | A list and comparison of filesystem-to-S3 solutions and S3-compatible storage providers |
| **Proof of concept (PoC)** | A working demonstration of the selected storage setup |
| **Preliminary benchmarks** | A performance comparison with the existing My Drive implementation |

### Scope

The focus is **research, integration, and evaluation**; developing new software is not an expected deliverable. A successful result could provide a starting point for a future **Cloud Programming** project to integrate the solution into CrownLabs.

**Core technologies:** Kubernetes · S3-compatible object storage  
**Related technology:** Liqo

## Team

| Student | Student ID |
| --- | --- |
| Alberto Montrucchio | `s360540` |
| Matteo Minin | `s364179` |

## License

This project is licensed under the [Apache License 2.0](LICENSE).
