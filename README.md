# Nano OS
Welcome to Nano OS. This is a project where I attempt to make an OS.

# Prerequisites
To run the project, you must install all of the dependencies to be able to run the project.

Run the following command to install all of the dependencies:
```bash
sudo apt install qemu-system build-essential 
```

You will also need to install [NASM](http://nasm.us)

# Running the OS
1. Run `make`
    - This will assemble the boot.asm file into a binary which will then be turned into an image which qemu can run.

2. Run `make run`
    - This will call qemu to run the image and boot into the OS.