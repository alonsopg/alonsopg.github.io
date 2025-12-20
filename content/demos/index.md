---
title: "Demos 👾"
menu: "main"
_build: { list: never, render: always }
---
---

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px;">

  <article style="border:1px solid #e5e7eb;border-radius:12px;padding:16px;background:#f9fafb;">
    <h3 style="margin:0 0 8px 0;">EdTec-QBuilder</h3>
    <p style="margin:0 0 10px 0;">
      End-to-end demo of a document retrieval and ranking system for large text collections.
    </p>
    <p style="margin:0 0 10px 0;">
      The system applies vector-based semantic search followed by re-ranking to identify relevant documents, and then selects and orders them to assemble structured outputs. It exposes the full retrieval pipeline, including indexing, scoring, ranking, and selection logic.
    </p>
    <p style="margin:0 0 12px 0;">
      Designed to illustrate how retrieval, relevance modeling, and controlled composition can be combined in document-centric workflows.
    </p>
    <p style="margin:0;">
      <a href="https://www.dfki.de/kiperweb/index.html" target="_blank" rel="noopener">View demo 🔗</a>
    </p>
  </article>

  <article style="border:1px solid #e5e7eb;border-radius:12px;padding:16px;background:#f9fafb;">
    <h3 style="margin:0 0 8px 0;">EdTec-ItemGen</h3>
    <p style="margin:0 0 10px 0;">
      Demo of a retrieval-augmented generation pipeline for document-based text generation.
    </p>
    <p style="margin:0 0 10px 0;">
      The system combines document chunking, semantic retrieval, and key point extraction with LLM-based generation. Retrieved evidence is injected into prompts to ensure generated text remains grounded in source documents.
    </p>
    <p style="margin:0 0 12px 0;">
      The demo highlights prompt orchestration, traceability of generated content, and basic controls for evaluating and inspecting model outputs in document-heavy settings.
    </p>
    <p style="margin:0;">
      <a href="https://edtec-itemgen.xyz/" target="_blank" rel="noopener">View demo 🔗</a>
    </p>
  </article>

</div>
