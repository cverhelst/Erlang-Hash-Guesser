from Crypto.Hash import MD5
from timeit import Timer

def numbers(n):
	if n >= 48 and n < 57:
		return n+1,"next"
	else:
		return 48, "reset"

def increment(list):
	if not list:
		return [numbers(0)[0]]
	else:
		head = list.pop(0)
		n, action = numbers(head)
		if action == "next":
			list.insert(0,n)
			return list
		elif action == "reset":
			list = increment(list)
			list.insert(0,n)
			return list
			
def hexstring(list):
	hex = []
	for e in list:
		hex.append(chr(e))
	return ''.join(hex)
		
def main(depth):
	t = Timer(stmt=("loop([],%d,[])"%depth), setup="from __main__ import loop")
	print t.timeit(1)
	# loop([],depth,[])
	
def loop(list,depth,base):
	message = "not_found"
	while len(list) <= depth:
		list = increment(list)
		full = list
		full.extend(base)
		hash = MD5.new(hexstring(full)).digest()
		if hash == "d3eb9a9233e52948740d7eb8c3062d14":
			message = "found %s" % full
			break
	print message
	


if __name__ == '__main__':
	main(6)