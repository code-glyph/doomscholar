"""Text chunker: splits parsed sections into fixed-size overlapping chunks."""


def chunk_sections(
    sections: list[dict],
    chunk_size: int = 800,
    overlap: int = 150,
) -> list[dict]:
    """
    Takes a list of {"text": str, "source_location": str} sections
    and returns a flat list of chunks:
      {"chunk_text": str, "source_location": str, "chunk_index": int}

    Sections shorter than chunk_size are kept as-is.
    Longer sections are split with a sliding window.
    """
    chunks = []
    chunk_index = 0

    for section in sections:
        text = section["text"]
        source = section["source_location"]

        if len(text) <= chunk_size:
            chunks.append({
                "chunk_text": text,
                "source_location": source,
                "chunk_index": chunk_index,
            })
            chunk_index += 1
        else:
            start = 0
            while start < len(text):
                end = min(start + chunk_size, len(text))
                chunks.append({
                    "chunk_text": text[start:end],
                    "source_location": source,
                    "chunk_index": chunk_index,
                })
                chunk_index += 1
                if end == len(text):
                    break
                start += chunk_size - overlap

    return chunks
