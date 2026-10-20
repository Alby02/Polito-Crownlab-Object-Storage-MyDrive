# S3 FileSystem

## Requirements
- Expose S3 as a mounted FS inside a VM
- Allows all basic FS operations (Read, Write, ...)

## Candidates
1. [ZeroFS](https://github.com/Barre/zerofs)
    * \+ POSIX-conformant
    * \+ Good speed with large files
2. [DittoFS](https://dittofs.io/docs/getting-started/getting-started/)
    * \+ No FUSE
    * \- No production ready
3. [JuiceFS](https://juicefs.com/en/)
    * \+ POSIX-conformant
4. [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse)
5. [geesefs](https://github.com/yandex-cloud/geesefs)
6. [rclone](https://rclone.org)
    * \- Complex

# Evaluation criteria
TODO: select critiera and compare candidates
| Criterion | What we check | Required? |
|---|---|---|
| Basic file operations | Read, write, ... |  Yes |
| Isolation | A user can only access their own data |  Yes |
| Portability (Liqo) | Supports portability | Yes |
| Small files | Speed with many small files |  No |
| Large files | Speed with large files |  No |
| Concurrent access | Behavior under concurrent access| No |
| License | ? |  ? |

## Q&A
- **Q**: Which is the most common use case we should focus on? (e.g. most operations are reads, writes...)<br>
**A**: TODO

- **Q**: Is it possible to connect to the same bucket from two different namespaces?<br>
**A**: Yes, even tho 2 different namespaces can't share a single PVC, it's allowed to generate more PVC (with a single PV per namespace) pointing to the same bucket. (Source: [GitHub](https://github.com/awslabs/mountpoint-s3-csi-driver/issues/244))<br>

- **Q**: What happens for concurrent writes when using multiple PVC from different namespaces?<br>
**Sub A**: TODO

## Other Resourcers
- Why S3 as a fs is a bad idea? (Source: [Reddit](https://www.reddit.com/r/aws/comments/dplfoa/why_is_s3fs_such_a_bad_idea/?tl=it))