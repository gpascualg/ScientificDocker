import os
import argparse
import re
import subprocess
from getpass import getpass


def subprocess_cmd(command, cin=None):
    print(command)
    process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    if cin is not None:
        process.communicate(cin)
    process.wait()
    return process.returncode


def main():
    parser = argparse.ArgumentParser(description='Build options.')
    parser.add_argument('--tag', required=True)
    parser.add_argument('--ubuntu-version', default='18.04')
    parser.add_argument('--python-version', default='3')
    parser.add_argument('--dir', default='.')
    parser.add_argument('--tensorflow', action='store_true')
    parser.add_argument('--tensorflow-version', default='r1.0')
    parser.add_argument('--tensorflow-generic', action='store_true')
    parser.add_argument('--bazel-version', default='0.17.2')
    parser.add_argument('--nccl-version', default='2')
    parser.add_argument('--rocksdb-version', default='v5.15.10')
    parser.add_argument('--caffe', action='store_true')
    parser.add_argument('--gpu', action='store_true')
    parser.add_argument('--cuda-version', default='9.2')
    parser.add_argument('--cudnn-version', default='7')
    parser.add_argument('--opencl', action='store_true')
    parser.add_argument('--ssh', action='store_true')
    parser.add_argument('--push', action='store_true')
    parser.add_argument('--no-jupyter-lab', default=False, action='store_true')
    parser.add_argument('--jupyter-coranos', default=False, action='store_true')
    parser.add_argument('--half-precision', action='store_true')

    args = parser.parse_args()

    compute_capabilities = '3.5,5.2'
    base = 'ubuntu:{}'.format(args.ubuntu_version)

    if args.gpu:
        base = 'nvidia/cuda:{}-cudnn{}{}-ubuntu{}'
        base = base.format(
            args.cuda_version, 
            args.cudnn_version,
            '' if args.tensorflow_generic else '-devel',
            args.ubuntu_version
        )

    if args.half_precision:
        compute_capabilities += ',6.0,6.1'

    data = {
        'python_version27': int(args.python_version) == 2,
        'tensorflow_dependencies': int(args.tensorflow or args.tensorflow_generic),
        'build_tensorflow': int(args.tensorflow and not args.tensorflow_generic),
        'tensorflow_generic': int(args.tensorflow_generic),
        'tensorflow_version': args.tensorflow_version,
        'bazel_version': args.bazel_version,
        'nccl_version': args.nccl_version,
        'rocksdb_version': args.rocksdb_version,
        'build_caffe': int(args.caffe),
        'jupyter_lab': not bool(args.no_jupyter_lab),
        'coranos': bool(args.jupyter_coranos),
        'base': base,
        'cuda_version': args.cuda_version,
        'cudnn_version': args.cudnn_version,
        'use_cuda': 1 if args.gpu else 0,
        'use_opencl': int(args.opencl),
        'compute_capabilities': compute_capabilities,
        'ssh': int(args.ssh)
    }

    write_stack = [(None, True)]

    with open(os.path.join(args.dir, 'Dockerfile.template'), 'r') as fin:
        with open(os.path.join(args.dir, 'Dockerfile'), 'w') as fout:
            for line in fin:
                match = re.match(r"\[\[if (\w+)\]\]", line)
                if match is not None:
                    if not write_stack[-1][1]:
                        write_stack.append([match.group(1), None])
                    else:
                        write_stack.append([match.group(1), data[match.group(1)]])
                    continue

                match = re.match(r"\[\[endif\]\]", line)
                if match is not None:
                    write_stack.pop(len(write_stack) - 1)
                    continue

                match = re.match(r"\[\[else\]\]", line)
                if match is not None:
                    if write_stack[-1][1] is not None:
                        write_stack[-1][1] = not write_stack[-1][1]
                    continue

                if write_stack[-1][1] is None or not write_stack[-1][1]:
                    continue

                match = re.match(r".*?({{(\w+)}}).*?", line)
                if match is not None:
                    line = line.replace(match.group(1), str(data[match.group(2)]))

                fout.write(line)

    if subprocess.call(['docker', 'build', '-t', args.tag, args.dir]) == 0:
        print('')
        print("----- DONE -----")

        with open('latest', 'w') as fp:
            fp.write(args.tag)

        if args.push:
            #username = raw_input('Username: ')
            #password = getpass()

            if subprocess.call(['docker', 'login']) == 0:
                if subprocess.call(['docker', 'push', args.tag]) == 0:
                    print('')
                    print("----- PUSHED -----")
        


if __name__ == '__main__':
    main()
