"""Payment ledger."""


def total(entries):   
    return sum(e["amount"] for e in entries)
