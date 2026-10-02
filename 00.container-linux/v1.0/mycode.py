# 볼륨(/mycode)이 어떻게 동작하는지 확인하려고 넣어 두는 아주 작은 스크립트.
import platform, socket

print("hello from", socket.gethostname())
print("python", platform.python_version(), "/", platform.system(), platform.machine())
