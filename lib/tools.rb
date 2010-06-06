def with(value)
    yield(value)
end

def sh2(cmd)
	sh cmd, :verbose => false
end