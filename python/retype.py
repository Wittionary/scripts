# Takes in a text file, waits for a moment, and then retypes the file contents in whatever window is selected
# Use case: I can't copy a PEM file from my laptop to a VM without configuration changes to the VM, but I do have RDP access
# So, I'll run the script, select an empty notepad window open on the VM via RDP, and get the contents that way
# Use checksums to verify the files match and latency hasn't adversely affected typing
import sys
import pyautogui
import hashlib
from os.path import exists
from tkinter import Tk

try:
    UsingClipboard = False
    FilePath = sys.argv[1]
    FileExists = exists(FilePath)
    if not FileExists:
        exit("A valid file was not found. Verify the file path.")

    # Ensure the file you end with is the same as the one you start with
    with open(FilePath, "rb") as FileObject:
        bytes = FileObject.read()
        filehash = hashlib.md5(bytes).hexdigest()

except:
    UsingClipboard = True
    print("Trying clipboard contents.")
    clipboard = Tk().clipboard_get()
    

if UsingClipboard:
    print(f"Clipboard: {clipboard[0:15]}...")
else:
    print(f"File: {FilePath}")

print("Waiting for user to select text field to type in...")
print("Starting in ", end='')
pyautogui.countdown(10)

if UsingClipboard:
    pyautogui.write(clipboard, 0.001)
else:
    with open(FilePath) as FileObject:
        for Line in FileObject:
            print(f"Typing: {Line}")
            pyautogui.write(Line, 0.001)
            print(f"Ensure the hash of the destination file matches the following\nmd5 hash: {filehash}")

print("Typing complete.")