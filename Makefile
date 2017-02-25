check: t/fixture/done
	tclsh messagepack.test

t/fixture/done: mkfixture.py
	mkdir -p t/fixture && python mkfixture.py && touch t/fixture/done

clean:
	rm -f t/fixture/*
